import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel
import "colors.js" as Colors

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "transparent"
    readonly property real s: width / 1920
    property real screenCornerRadius: 26

    // Palette
    readonly property color foreground: Colors.foreground
    readonly property color accent: Colors.accent
    readonly property color accentMuted: Colors.accentMuted
    readonly property color highlight: Colors.highlight
    
    // State
    property int  userIndex:    userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int  sessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool sessionMenuOpen: false
    property bool userMenuOpen: false

    FontLoader {
        id: aceFont
        source: "font/ace_futurism.ttf"
    }

    FolderListModel {
        id: backgroundFiles
        folder: Qt.resolvedUrl(".")
        nameFilters: ["bg.*"]
        showDirs: false
    }

    readonly property url backgroundSource: backgroundFiles.count > 0
        ? backgroundFiles.get(0, "fileUrl")
        : ""
    readonly property string backgroundFileName: backgroundFiles.count > 0
        ? backgroundFiles.get(0, "fileName")
        : ""
    readonly property bool useVideoBackground: /\.(mp4|webm|mkv|avi|mov|m4v)$/i.test(backgroundFileName)

    ListView { 
        id: sessionHelper
        model: sessionModel
        currentIndex: root.sessionIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string sName: (model && model.name) ? model.name : ""
        }

    }
    
    ListView { 
        id: userHelper
        model: userModel
        currentIndex: root.userIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item { 
            property string uName: (model && (model.realName || model.name)) ? (model.realName || model.name) : ""
            property string uLogin: (model && model.name) ? model.name : "" 
        } 

    }

    function login() {
        var n = ""
        if (userHelper.currentItem && userHelper.currentItem.uName !== "") {
            n = userHelper.currentItem.uLogin
        } else {
            n = userModel.lastUser
        }
        sddm.login(n, passInput.text, root.sessionIndex)
    }

    function selectSession(index) {
        if (!sessionModel || index < 0 || index >= sessionModel.count)
            return
        root.sessionIndex = index
        root.sessionMenuOpen = false
        root.userMenuOpen = false
    }

    function moveSession(delta) {
        if (!sessionModel || sessionModel.count === 0)
            return
        var index = root.sessionIndex + delta
        if (index < 0)
            index = sessionModel.count - 1
        else if (index >= sessionModel.count)
            index = 0
        root.sessionIndex = index
        root.sessionMenuOpen = true
        root.userMenuOpen = false
    }

    function selectUser(index) {
        if (!userModel || index < 0 || index >= userModel.count)
            return
        root.userIndex = index
        root.userMenuOpen = false
    }

    function moveUser(delta) {
        if (!userModel || userModel.count === 0)
            return
        var index = root.userIndex + delta
        if (index < 0)
            index = userModel.count - 1
        else if (index >= userModel.count)
            index = 0
        root.userIndex = index
        root.userMenuOpen = true
        root.sessionMenuOpen = false
    }

    Timer { interval: 300; running: true; onTriggered: passInput.forceActiveFocus() }

    // Background
    MediaPlayer {
        id: player
        source: root.useVideoBackground ? root.backgroundSource : ""
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        onSourceChanged: {
            if (source !== "")
                player.play()
        }
    }

    Image {
        id: bgImage
        anchors.fill: parent
        source: root.useVideoBackground ? "" : root.backgroundSource
        fillMode: Image.PreserveAspectCrop
        visible: !root.useVideoBackground
        z: -500
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root.useVideoBackground
        z: -500
    }
    
    Rectangle { 
        anchors.fill: parent
        z: -300
        gradient: Gradient { 
            GradientStop {
                position: 0.0
                color: "#45000000"
            }
            GradientStop {
                position: 1.0
                color: "#75000000"
            }
        } 
    }


    // Clock Widget
    Item {
        id: clockWidget
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.top: parent.top
        anchors.topMargin: 60 * s
        width: 450 * s
        height: 250 * s
        property real clockScale: 1.3
        scale: clockScale
        transformOrigin: Item.TopRight

        Item {
            id: orbitalSpace
            anchors.centerIn: timeLabels
            width: 320 * s
            height: 100 * s
            rotation: -18
            z: 10 

            property real t: 0
            NumberAnimation on t {
                from: 0; to: Math.PI * 2
                duration: 18000
                loops: Animation.Infinite
                running: true
            }

            Shape {
                anchors.fill: parent
                opacity: 0.25
                antialiasing: true
                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: root.highlight
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathAngleArc {
                        centerX: 160 * s; centerY: 50 * s
                        radiusX: 160 * s; radiusY: 50 * s
                        startAngle: 0; sweepAngle: 360
                    }
                }

            }

            Rectangle {
                id: traveler
                width: 8 * s; height: 8 * s; radius: 4 * s
                color: root.highlight
                opacity: 0.6
                antialiasing: true
                x: (160 * s) + (160 * s * Math.cos(orbitalSpace.t)) - (width / 2)
                y: (50 * s) + (50 * s * Math.sin(orbitalSpace.t)) - (height / 2)
            }
        }

        Row {
            id: timeLabels
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15 * s
            z: 50 

            Text {
                id: hhLab
                text: Qt.formatTime(new Date(), "HH")
                font.family: aceFont.name
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.foreground
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
            Text {
                text: ":"
                font.family: aceFont.name
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.foreground
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
            Text {
                id: mmLab
                text: Qt.formatTime(new Date(), "mm")
                font.family: aceFont.name
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.foreground
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
        }

        Column {
            anchors.right: parent.right
            anchors.top: timeLabels.bottom
            anchors.topMargin: 0
            spacing: 5 * s
            z: 100 
            
            Text {
                text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                font.family: aceFont.name
                font.pixelSize: 16 * s
                font.letterSpacing: 8 * s
                color: root.accent
                opacity: 0.8
                anchors.right: parent.right
            }
            
            Row {
                anchors.right: parent.right
                spacing: 12 * s
                Rectangle { width: 40 * s; height: 1; color: root.accent; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: Qt.formatDate(new Date(), "MMM dd yyyy").toUpperCase()
                    font.family: aceFont.name
                    font.pixelSize: 12 * s
                    font.letterSpacing: 4 * s
                    color: root.foreground
                    opacity: 0.6
                }
            }
        }

        Timer { 
            interval: 1000
            running: true
            repeat: true
            onTriggered: { 
                hhLab.text = Qt.formatTime(new Date(), "HH")
                mmLab.text = Qt.formatTime(new Date(), "mm") 
            } 
        }
    }

    // Identity System
    Column {
        id: identityStack
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 12 * s
        width: 450 * s

        SequentialAnimation {
            id: typingAnim
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.0; to: 1.01
                duration: 40
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.01; to: 1.0
                duration: 100
            }
        }

        Item {
            width: parent.width
            height: uLabel.height
            z: 2000
            Text {
                id: uLabel
                text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "UNKNOWN").toUpperCase()
                font.family: aceFont.name
                font.pixelSize: 70 * s
                font.letterSpacing: 10 * s
                color: (root.userMenuOpen || uMa.containsMouse) ? root.accent : root.foreground
                anchors.right: parent.right
                scale: uMa.containsMouse ? 1.05 : 1.0
                transformOrigin: Item.Right
                
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
                
                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.userMenuOpen = !root.userMenuOpen
                        root.sessionMenuOpen = false
                    }
                }
            }
            Item {
                id: uMenu
                anchors.bottom: uLabel.top
                anchors.bottomMargin: 20 * s
                anchors.right: parent.right
                width: 320 * s
                height: root.userMenuOpen ? (40 * s * userModel.count) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.accent
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: userModel
                        delegate: Item {
                            width: 300 * s
                            height: 32 * s
                            property bool itemHover: uItemMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 18 * s
                                color: root.accent
                                anchors.right: parent.right
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: (model.realName || model.name).toUpperCase()
                                font.family: aceFont.name
                                font.pixelSize: 24 * s
                                font.letterSpacing: 2 * s
                                color: root.foreground
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0.4
                                anchors.right: parent.right
                                anchors.rightMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                id: uItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selectUser(index)
                                }
                            }
                        }
                    }

                }
            }
        }
        Row {
            anchors.right: parent.right
            spacing: 12 * s
            Rectangle {
                width: 60 * s
                height: 1
                color: root.accent
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "✦"
                font.pixelSize: 10 * s
                color: root.accent
                opacity: 0.4
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 60 * s
                height: 1
                color: root.accent
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: inputWrapper
            width: parent.width
            height: 48 * s

            ShaderEffectSource {
                id: wallpaperRegion
                anchors.fill: parent
                sourceItem: root.useVideoBackground ? bgVideo : bgImage
                sourceRect: {
                    var point = inputWrapper.mapToItem(sourceItem, 0, 0)
                    return Qt.rect(point.x, point.y, width, height)
                }
                hideSource: false
                live: true
                smooth: true
                visible: false
            }

            FastBlur {
                id: blurredWallpaper
                anchors.fill: parent
                source: wallpaperRegion
                radius: 24
                transparentBorder: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: roundedMask
                }
            }

            Rectangle {
                id: roundedMask
                anchors.fill: parent
                anchors.leftMargin: 8 * s
                anchors.rightMargin: -8 * s
                color: "white"
                radius: 24 * s
                visible: false
            }

            TextInput {
                id: passInput
                anchors.right: parent.right
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8 * s
                anchors.rightMargin: -8 * s
                
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignRight
                echoMode: TextInput.Password
                passwordCharacter: "✦"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
                font.family: aceFont.name
                font.pixelSize: 20 * s
                font.letterSpacing: 10 * s
                color: root.accent
                focus: true
                property bool wasClicked: false
                
                cursorVisible: false
                cursorDelegate: Item {
                    width: 0; height: 0
                }
                
                selectionColor: root.accent

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Down) {
                        if (root.userMenuOpen) {
                            root.moveUser(1)
                            event.accepted = true
                        } else if (root.sessionMenuOpen) {
                            root.moveSession(1)
                            event.accepted = true
                        }
                    } else if (event.key === Qt.Key_Up) {
                        if (root.userMenuOpen) {
                            root.moveUser(-1)
                            event.accepted = true
                        } else if (root.sessionMenuOpen) {
                            root.moveSession(-1)
                            event.accepted = true
                        }
                    } else if (event.key === Qt.Key_Escape && (root.sessionMenuOpen || root.userMenuOpen)) {
                        root.sessionMenuOpen = false
                        root.userMenuOpen = false
                        event.accepted = true
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && (root.sessionMenuOpen || root.userMenuOpen)) {
                        root.sessionMenuOpen = false
                        root.userMenuOpen = false
                        event.accepted = true
                    }
                }

                leftPadding: 18 * s
                rightPadding: 18 * s + (passInput.text.length > 0 ? 50 * s : 0)
                Behavior on rightPadding {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }
                
                onTextChanged: {
                    typingAnim.restart()
                }
                
                onAccepted: {
                    root.login()
                }
                
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WAITING  FOR  PASSWORD    "
                    font.family: aceFont.name
                    font.pixelSize: 16 * s
                    font.letterSpacing: 3 * s
                    color: root.accent
                    
                    // CINEMATIC FADE: Restores smoothly when deleting
                    opacity: passInput.text.length === 0 ? 0.85 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.InOutSine
                        }
                    }
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 3
                    }
                }
                
                Rectangle {
                    id: customCursor
                    width: 2 * s
                    height: 24 * s
                    color: root.accent
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x
                    visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)
                    
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: customCursor.visible
                        NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                        NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passInput.forceActiveFocus()
                        passInput.wasClicked = true
                    }
                }
            }
            
            Item {
                id: loginBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32 * s
                height: 32 * s
                opacity: passInput.text.length > 0 ? 0.8 : 0
                scale: passInput.text.length > 0 ? 1.0 : 0.8
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutBack
                    }
                }
                
                Text {
                    text: "✦"
                    font.pixelSize: 14 * s
                    color: arrowMa.containsMouse ? root.accent : root.foreground
                    anchors.centerIn: parent
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 4
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.accent
                    border.width: 1
                    opacity: 0.2
                    rotation: 45
                }
                
                MouseArea {
                    id: arrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.login()
                    }
                }
            }
        }
    }

    // Logistics Menu
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 15 * s
        z: 1000

        Item {
            width: sLabel.width
            height: sLabel.height
            Text {
                id: sLabel
                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "WAYLAND").toUpperCase()
                font.family: aceFont.name
                font.pixelSize: 24 * s
                font.letterSpacing: 4 * s
                color: (root.sessionMenuOpen || sMa.containsMouse) ? root.accentMuted : root.accent
                opacity: 0.8
                
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 4
                }
                
                MouseArea {
                    id: sMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionMenuOpen = !root.sessionMenuOpen
                        root.userMenuOpen = false
                    }
                }
            }
            Item {
                id: sMenu
                anchors.bottom: parent.top
                anchors.bottomMargin: 20 * s
                anchors.left: parent.left
                width: 320 * s
                height: root.sessionMenuOpen ? (40 * s * sessionModel.count) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.accent
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: sessionModel
                        delegate: Item {
                            width: 250 * s
                            height: 32 * s
                            property bool itemHover: mMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 12 * s
                                color: root.accent
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: model.name.toUpperCase()
                                font.family: aceFont.name
                                font.pixelSize: 20 * s
                                font.letterSpacing: 2 * s
                                color: root.foreground
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0.4
                                anchors.left: parent.left
                                anchors.leftMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                id: mMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selectSession(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            spacing: 25 * s
            Text { 
                text: "REBOOT"
                font.family: aceFont.name
                font.pixelSize: 16 * s
                font.letterSpacing: 4 * s
                color: root.foreground
                opacity: rMa.containsMouse ? 1.0 : 0.4
                scale: rMa.containsMouse ? 1.05 : 1.0
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
                
                MouseArea {
                    id: rMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        sddm.reboot()
                    }
                }
            }
            Rectangle {
                width: 1
                height: 10 * s
                color: root.accent
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text { 
                text: "SHUTDOWN"
                font.family: aceFont.name
                font.pixelSize: 16 * s
                font.letterSpacing: 4 * s
                color: root.foreground
                opacity: pMa.containsMouse ? 1.0 : 0.4
                scale: pMa.containsMouse ? 1.05 : 1.0
                
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
                
                MouseArea {
                    id: pMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        sddm.powerOff()
                    }
                }
            }
        }
    }

    Shape {
        anchors.fill: parent
        z: 9999
        ShapePath {
            fillColor: "#000000"
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine { x: root.screenCornerRadius * root.s; y: 0 }
            PathAngleArc {
                centerX: root.screenCornerRadius * root.s
                centerY: root.screenCornerRadius * root.s
                radiusX: root.screenCornerRadius * root.s
                radiusY: root.screenCornerRadius * root.s
                startAngle: -90
                sweepAngle: -90
            }
            PathLine { x: 0; y: root.screenCornerRadius * root.s }
            PathLine { x: 0; y: 0 }
        }
        ShapePath {
            fillColor: "#000000"
            strokeColor: "transparent"
            startX: root.width
            startY: 0
            PathLine { x: root.width - root.screenCornerRadius * root.s; y: 0 }
            PathAngleArc {
                centerX: root.width - root.screenCornerRadius * root.s
                centerY: root.screenCornerRadius * root.s
                radiusX: root.screenCornerRadius * root.s
                radiusY: root.screenCornerRadius * root.s
                startAngle: -90
                sweepAngle: 90
            }
            PathLine { x: root.width; y: root.screenCornerRadius * root.s }
            PathLine { x: root.width; y: 0 }
        }
        ShapePath {
            fillColor: "#000000"
            strokeColor: "transparent"
            startX: 0
            startY: root.height
            PathLine { x: root.screenCornerRadius * root.s; y: root.height }
            PathAngleArc {
                centerX: root.screenCornerRadius * root.s
                centerY: root.height - root.screenCornerRadius * root.s
                radiusX: root.screenCornerRadius * root.s
                radiusY: root.screenCornerRadius * root.s
                startAngle: 90
                sweepAngle: 90
            }
            PathLine { x: 0; y: root.height - root.screenCornerRadius * root.s }
            PathLine { x: 0; y: root.height }
        }
        ShapePath {
            fillColor: "#000000"
            strokeColor: "transparent"
            startX: root.width
            startY: root.height
            PathLine { x: root.width; y: root.height - root.screenCornerRadius * root.s }
            PathAngleArc {
                centerX: root.width - root.screenCornerRadius * root.s
                centerY: root.height - root.screenCornerRadius * root.s
                radiusX: root.screenCornerRadius * root.s
                radiusY: root.screenCornerRadius * root.s
                startAngle: 0
                sweepAngle: 90
            }
            PathLine { x: root.width - root.screenCornerRadius * root.s; y: root.height }
            PathLine { x: root.width; y: root.height }
        }
    }
}
