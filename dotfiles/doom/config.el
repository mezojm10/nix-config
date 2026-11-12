;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "Iosevka" :size 14 :weight 'semi-light))
(setq doom-symbol-font (font-spec :family "Iosevka" :size 14 :weight 'semi-light))
;;
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'noctalia)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

(menu-bar-mode -1)
;; Enable treesitter and lsp when using OCaml
(add-hook! tuareg-mode-hook (tree-sitter-hl-mode))
(add-hook! tuareg-mode-hook (lsp-mode))

;; Enable lsp when using vue
(add-hook! vue-mode-hook (lsp))

;; Enable treesitter when using Go
(add-hook! go-mode-hook (tree-sitter-hl-mode))

;; Enable Haskell formatter
(after! lsp-haskell
  (setq lsp-haskell-formatting-provider "fourmolu"))

;; accept completion from copilot and fallback to company
(use-package! copilot
  :hook (prog-mode . copilot-mode)
  :bind (:map copilot-completion-map
              ("C-y" . 'copilot-accept-completion)
              ("S-C-y" . 'copilot-accept-completion-by-word)
              ))
;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;; ════════════════════════════════════════════════════════════════════════════
;; Frames instead of Emacs windows — niri owns the window layout
;; ════════════════════════════════════════════════════════════════════════════

;; New frames should join the *current* workspace, not spawn a fresh `#N` one.
;; Doom's `workspaces` module otherwise runs `+workspaces-associate-frame-fn`
;; (which creates a new perspective) for every frame. `-1` un-registers that
;; override so persp-mode falls back to its default: reuse the last-active
;; workspace (`persp-set-last-persp-for-new-frames` is already `t`).
(after! persp-mode
  (setq persp-interactive-init-frame-behaviour-override -1
        persp-emacsclient-init-frame-behaviour-override -1))

;; Manual split keys (C-w s / C-w v, and Doom's C-w S / C-w V "follow"
;; variants) open a new frame instead of splitting the current one. Direction is
;; irrelevant now that niri does the tiling, so all four just make a frame.
(map! :map evil-window-map
      "s" #'make-frame-command
      "v" #'make-frame-command
      "S" #'make-frame-command
      "V" #'make-frame-command)

;; Auto-popups (help, magit, org links, lsp, etc.) also open a new frame
;; instead of splitting. Note: Doom's `(popup +defaults)` module adds its own
;; `display-buffer-alist` rules that would override this for buffers like
;; `*Help*`; see init.el where that module is disabled.
(setq display-buffer-base-action
      '((display-buffer-reuse-window display-buffer-pop-up-frame)
        (reusable-frames . t)))

;; `frames-only-mode` smooths the rough edges of a frames-only workflow: it
;; deletes the frame when magit/help/completions are closed (no leftover empty
;; frames), keeps completion popups in-window, and tunes org/ediff/ido.
(use-package! frames-only-mode
  :config
  (frames-only-mode +1))
