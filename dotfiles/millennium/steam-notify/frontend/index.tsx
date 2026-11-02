// Steam notifications as native desktop notifications via notify-send.
//
// Desktop toasts all go through window.NotificationStore.DispatchNextToast():
// it takes the head of m_rgNotificationToasts and hands it to the toast window.
// This wrapper drains the queue first, so Steam sees it empty and draws
// nothing, and the text is forwarded to the Lua backend.
//
// In-game overlay toasts (m_mapAppOverlayToasts) and Steam sounds are untouched.
import { definePlugin, Field } from 'millennium';

const w = window as any;

type Toast = { notificationID: unknown; eType: number; eSource: number; data: any };

// Labels from GetNotificationTargets()[eType].strTest. Steam's casing varies,
// so keys are lowercased. {game} is replaced with the game name from the toast.
const LABELS: Record<string, string> = {
	'friend message': 'message',
	'group chat msg': 'group message',
	'friend invite rollup': 'friend requests',
	'friend invite': 'friend request',
	'friend online': 'online',
	'friend in game': 'playing {game}',
	'gift received': 'gift',
	'wishlist': 'wishlist discount: {game}',
	'trade offer': 'trade offer',
	'comment': 'comment',
	'screenshot': 'screenshot',
	'cloud sync conflict': 'Steam Cloud conflict: {game}',
	'cloud sync failure': 'Steam Cloud sync failed: {game}',
	'incoming voice chat': 'incoming voice call',
	'system update': 'system update',
	'hardware update': 'device update',
	'hardware survey': 'hardware survey',
	'item announcement': 'new items',
	'download complete': 'download complete: {game}',
};

const STEAMID64_BASE = BigInt('76561197960265728');

function friendName(id: unknown): string | undefined {
	if (id === undefined || id === null || id === '') return undefined;
	try {
		const n = BigInt(id as string | number);
		const account = Number(n >= STEAMID64_BASE ? n - STEAMID64_BASE : n);
		return w.friendStore?.GetFriendState?.(account)?.display_name || undefined;
	} catch {
		return undefined;
	}
}

function appName(appid: unknown): string | undefined {
	if (!appid) return undefined;
	try {
		return w.appStore?.GetAppOverviewByAppID?.(Number(appid))?.display_name || undefined;
	} catch {
		return undefined;
	}
}

// Client notifications carry protobuf (toObject); server ones carry JSON in
// item.body_data.
function payload(t: Toast): any {
	try {
		if (t.eSource === 2) return JSON.parse(t.data?.item?.body_data ?? '{}');
		return t.data?.toObject?.() ?? {};
	} catch {
		return {};
	}
}

function describe(t: Toast, label: string): { title: string; body: string } {
	const o = payload(t);
	const sender = o.steamid ?? o.requestor_id ?? o.gifter_account ?? o.accountid_owner ?? o.steamid_sender;
	// Friends may not be loaded right after Steam starts; fall back to "friend".
	const who = sender ? friendName(sender) || 'A friend' : undefined;
	// Friend and group chat messages already have a title and body.
	if (o.title || o.body) return { title: String(o.title || who || 'Steam'), body: String(o.body || label) };
	const game = o.game_name || appName(o.appid) || '';
	const text = label.includes('{game}')
		? (game ? label.replace('{game}', game) : label.replace(/:? ?\{game\}/, ''))
		: [label, game].filter(Boolean).join(': ');
	if (who) return { title: who, body: text };
	// Without a sender, use the event as the title and the game as the body.
	const head = label.replace(/:? ?\{game\}/, '');
	if (head) return { title: head[0].toUpperCase() + head.slice(1), body: game };
	return { title: 'Steam', body: game || 'notification' };
}

function forward(store: any, t: Toast) {
	const target = store.GetNotificationTargets?.()?.[t.eType];
	const strTest: string | undefined = target?.strTest;
	const label = (strTest && LABELS[strTest.toLowerCase()]) || strTest || '';
	const { title, body } = describe(t, label);
	backend.notify(title, body, target?.bCritical ? 'critical' : 'normal');
}

function install(): boolean {
	const store = w.NotificationStore;
	if (!store?.DispatchNextToast || !Array.isArray(store.m_rgNotificationToasts)) return false;
	if (store.__steamNotify) return true;
	const original = store.DispatchNextToast;
	store.DispatchNextToast = function (this: any, ...args: unknown[]) {
		const queue: Toast[] = this.m_rgNotificationToasts;
		while (queue.length) {
			const t = queue.shift()!;
			try {
				forward(this, t);
			} catch (e) {
				backend.log(`forward failed: ${e}`);
			}
		}
		return original.apply(this, args);
	};
	store.__steamNotify = true;
	backend.log('hooked NotificationStore.DispatchNextToast');
	return true;
}

export default definePlugin(() => {
	// NotificationStore is created together with the Steam UI; wait for it.
	if (!install()) {
		const timer = setInterval(() => install() && clearInterval(timer), 500);
	}
	return {
		title: 'Steam notifications',
		icon: <span>🔔</span>,
		content: <Field label="Steam notifications are sent through notify-send" />,
	};
});
