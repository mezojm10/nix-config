import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.modelData?.onClicked(root.list)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        ClipRect {
            id: thumbnail

            visible: !!root.modelData?.thumbPath
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: parent.height
            implicitWidth: implicitHeight * 16 / 9
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Image {
                anchors.fill: parent
                source: thumbnail.visible ? `file://${root.modelData.thumbPath}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        MaterialIcon {
            id: icon

            visible: !thumbnail.visible
            anchors.verticalCenter: parent.verticalCenter
            text: "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
        }

        StyledText {
            anchors.left: thumbnail.visible ? thumbnail.right : icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.label ?? ""
            font: Tokens.font.body.medium
            elide: Text.ElideRight
        }
    }
}
