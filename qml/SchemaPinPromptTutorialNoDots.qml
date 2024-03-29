/*
 * Copyright 2014-2016 Canonical Ltd.
 * Copyright 2022 UBports Foundation
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3
import QtFeedback 5.0

Page {
    id: root
    objectName: "SchemaPinPrompt"

    property string text
    property bool isSecret
    property bool interactive: true
    property bool loginError: false
    property bool hasKeyboard: false //unused
    property string enteredText: ""
    property bool activeAreaVisible: false
    property bool displayPinCode: false
    property bool changeMode: false
    property string codeToTest: ""
    property string previousState: ""
    property int previousNumber: -1
    property var currentCode: []
    readonly property int maxnum: 10
    readonly property int minPinCodeDigits: 4
    readonly property bool validCode: enteredText.length >= minPinCodeDigits
    property bool isLandscape: root.width > root.height

    signal clicked()
    signal canceled()
    signal accepted(string response)

    onCurrentCodeChanged: {
        let tmpText = ""
        let tmpCode = ""
        const max = Math.max(minPinCodeDigits, currentCode.length, codeToTest.length )
        for( let i = 0; i < max; i++) {
            if (i < currentCode.length) {
                tmpText += '●'
                tmpCode += currentCode[i]
            } else {
                tmpText += '○'
            }
        }
        pinHint.text = tmpText
        root.enteredText = tmpCode

        if (root.state === "TEST_MODE" &&  (root.enteredText.length > 0) && root.enteredText.length == root.codeToTest.length) {
            if (root.enteredText === root.codeToTest) {
                root.state = "PASSWORD_SUCCESS"
            } else {
                root.state = "WRONG_PASSWORD"
            }
        }
    }

    function switchToTestMode() {
        root.state = "TEST_MODE"
    }

    function addNumber (number, fromKeyboard) {
        let tmpCodes = currentCode
        tmpCodes.push(number)
        currentCode = tmpCodes

        if (!fromKeyboard) {
            repeater.itemAt(number).animation.restart()
        }

        root.previousNumber = number
    }

    function removeOne() {
        let tmpCodes = currentCode
        tmpCodes.pop()
        currentCode = tmpCodes
    }

    function reset() {
        currentCode = []
        loginError = false;
        pinHint.forceActiveFocus()
    }


    header: PageHeader {
        id: pageHeader
        title: i18n.tr('Circle prompt')
        leadingActionBar {
            actions: [
                Action {
                    iconName: "back"
                    text: i18n.tr("back")
                    onTriggered: pageStack.pop()
                }
            ]
        }
        trailingActionBar {
            actions: [
                Action {
                    iconName: "edit"
                    visible: root.state === "TEST_MODE"
                    text: i18n.tr("edit")
                    onTriggered: root.state = "ENTRY_MODE"
                }
            ]
        }
    }

    HapticsEffect {
        id: hapticEffect
        attackIntensity: 0.0
        attackTime: 50
        intensity: 0.2
        duration: 10
        fadeTime: 50
        fadeIntensity: 0.0
    }


    Rectangle {
        anchors.fill: parent
        color: LomiriColors.lightAubergine
    }

    StyledItem {
        id: d

        readonly property color normal: theme.palette.normal.raisedText
        readonly property color selected: theme.palette.normal.raisedSecondaryText
        readonly property color selectedCircle: Qt.rgba(selected.r, selected.g, selected.b, 0.2)
        readonly property color disabled:theme.palette.disabled.raisedSecondaryText
    }

    GridLayout {
        id: grid
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        columns: isLandscape ? 2 : 1

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: units.gu(2)

            Label {
                id: topLabel
                anchors.horizontalCenter: parent.horizontalCenter
                fontSize: "large"

                text: " " // so that height will not be 0
                color: d.selected

                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: topLabel; property: "opacity"; to: 0 }
                        PropertyAction {}
                        NumberAnimation { target: topLabel; property: "opacity"; to: 1; duration: 500 }
                    }
                }
            }
            Rectangle {
                height: units.gu(4)
                width: parent.width
                color: "transparent"
                Text {
                    id: subtitle
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    wrapMode: Text.WordWrap

                    horizontalAlignment: Text.AlignHCenter
                    //fontSize: "medium"
                    text: i18n.tr("Click or swipe on the digits, click on the circle center to validate")
                    color: d.selected

                }
            }

            TextField {
                id: pinHint
                anchors.horizontalCenter: parent.horizontalCenter
                width: contentWidth + eraseIcon.width + units.gu(3)
                readOnly: true
                color: d.selected
                maximumLength: 12
                hasClearButton: false

                font {
                    pixelSize: units.gu(3)
                    letterSpacing: units.gu(1.2)
                }

                secondaryItem: Icon {
                    id: eraseIcon
                    name: "erase"
                    objectName: "EraseBtn"
                    height: units.gu(3)
                    width: units.gu(3)
                    color: enabled ? d.selected : d.disabled
                    enabled: root.currentCode.length > 0 && root.state !== "PASSWORD_SUCCESS"
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.removeOne()
                        onPressAndHold: root.reset()
                    }
                }


                inputMethodHints: Qt.ImhDigitsOnly

                Keys.onEscapePressed: {
                    root.canceled();
                    event.accepted = true;
                }

                Keys.onPressed: {
                    if(event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                        root.addNumber(event.text, true)
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace) {
                        root.removeOne()
                    }

                }

                Keys.onBackPressed: {
                    root.removeOne()
                }

            }

            Rectangle {
                height: units.gu(3)
                width: parent.width
                color: "transparent"
                Label {
                    color: d.selected
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: root.enteredText
                    opacity: root.displayPinCode ? 1.0 : 0.0
                    font {
                        pixelSize: units.gu(3)
                        letterSpacing: units.gu(1.2)
                    }
                }
            }
        }

        Rectangle {
            id: main
            objectName: "SelectArea"
            implicitHeight: root.width > root.height ? (root.width / grid.columns) * 0.8 : root.width * 0.8
            implicitWidth: implicitHeight

            Layout.fillWidth: true
            Layout.rowSpan: 2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            color: activeAreaVisible ?  Qt.rgba(d.selected.r, d.selected.g, d.selected.b, 0.1) : "transparent"
            border.color: activeAreaVisible ? d.selected : "transparent"

            MouseArea {
                id: mouseArea
                anchors.fill: parent

                onPositionChanged: {
                    if (pressed && root.enteredText.length < pinHint.maximumLength)
                        reEvaluate()
                }

                onReleased: {
                    if (root.validCode) {
                        var child = main.childAt(mouseX, mouseY)
                        if (child !== null && child.objectName === "CenterCircle") {
                            console.log('released')
                            child.animation.restart()
                            if (root.state !== "TEST_MODE") {
                                root.codeToTest = root.enteredText
                                root.state = "TEST_MODE"
                            } else {
                                if (root.enteredText === root.codeToTest) {
                                    root.state = "PASSWORD_SUCCESS"
                                } else {
                                    root.state = "WRONG_PASSWORD"
                                }
                            }
                        }
                    }
                }

                function reEvaluate() {
                    var child = main.childAt(mouseX, mouseY)

                    if (child !== null && child.number !== undefined) {
                        var number = child.number
                        if (number > -1 && ( root.previousNumber === -1 || number !== root.previousNumber)) {
                            root.addNumber(number)
                        }
                    } else {
                        root.previousNumber = -1
                    }
                }
            }

            Rectangle {
                id: center
                objectName: "CenterCircle"
                height: main.height / 3
                width: height
                radius: height / 2
                property int radiusSquared: radius * radius
                property alias locker: centerImg.source
                property alias animation: challengeAnim
                anchors.centerIn: parent
                color: "transparent"
                //border.color: d.normal
                property int number: -1

                Icon {
                    id: centerImg
                    source:  "image://theme/lock"
                    anchors.centerIn: parent
                    width: units.gu(4)
                    height: width
                    //anchors.margins: parent.height / 3
                    color: root.validCode ? d.selected : d.disabled
                    //fillMode: Image.PreserveAspectFit
                    onSourceChanged: imgAnim.start()

                }

                MouseArea {
                    id: centerMouseArea
                    anchors.fill: parent
                    propagateComposedEvents: true
                    onPressed: {
                        if (root.state === "PASSWORD_SUCCESS") {
                            root.state = "TEST_MODE"
                        }

                        if (root.state === "ENTRY_MODE") {
                            if (root.state === "ENTRY_MODE") {
                                root.codeToTest = root.enteredText
                                root.state = "TEST_MODE"
                            } else if (root.state === "EDIT_MODE") {
                                root.codeToTest = root.enteredText
                                root.state = "ENTRY_MODE"
                            } else {
                                if (currentCode.length >= minPinCodeDigits) {
                                    console.log('onPressed center')
                                    if (root.enteredText === root.codeToTest) {
                                        root.state = "PASSWORD_SUCCESS"
                                    } else {
                                        root.state = "WRONG_PASSWORD"
                                    }
                                }
                            }

                            root.previousState = root.state
                        }

                        mouse.accepted = false
                    }

                    onReleased: {
                        console.log('olala released')
                        if (root.state === "ENTRY_MODE" && (root.enteredText.length > minPinCodeDigits)) {
                            root.codeToTest = root.enteredText
                            root.state = "TEST_MODE"
                        } else {
//                            if (root.state === "TEST_MODE" &&  (root.enteredText.length > minPinCodeDigits)) {
//                                if (root.enteredText === root.codeToTest) {
//                                    root.state = "PASSWORD_SUCCESS"
//                                } else {
//                                    root.state = "WRONG_PASSWORD"
//                                }
//                            }
                        }



                        mouse.accepted = false
                    }
                }

                SequentialAnimation {
                    id: challengeAnim
                    ParallelAnimation {
                        PropertyAnimation {
                            target: centerImg
                            property: "color"
                            to: d.selected
                            duration: 100
                        }
                        PropertyAnimation {
                            target: center
                            property: "color"
                            to: d.selectedCircle
                            duration: 100
                        }
                    }
                    ParallelAnimation {

                        PropertyAnimation {
                            target: center
                            property: "color"
                            to: "transparent"
                            duration: 400
                        }
                    }
                }

                SequentialAnimation {
                    id: imgAnim
                    NumberAnimation { target: centerImg; property: "opacity"; from: 0; to: 1; duration: 1000 }
                }
            }

            // dots
            Repeater {
                id: repeater
                objectName: "dotRepeater"
                model: root.maxnum

                Rectangle {
                    id: selectionRect
                    height: bigR / 2.2
                    width: height
                    radius: height / 2
                    color: activeAreaVisible ? d.selected : "transparent"
                    opacity: activeAreaVisible ? 0.3 : 1.0
                    property int number: index
                    property alias dot: point
                    property alias animation: anim

                    property int bigR: root.state === "ENTRY_MODE" || root.state === "TEST_MODE" || root.state === "EDIT_MODE" ? main.height / 3 : 0
                    property int offsetRadius: radius
                    x: (main.width / 2) + bigR * Math.sin(2 * Math.PI * index / root.maxnum) - offsetRadius
                    y: (main.height / 2) - bigR * Math.cos(2 * Math.PI * index / root.maxnum) - offsetRadius

                    Text {
                        id: point
                        font.pixelSize: main.height / 10
                        anchors.centerIn: parent
                        color: d.disabled
                        text: index
                        opacity: root.state === "ENTRY_MODE" || root.state === "TEST_MODE" || root.state === "EDIT_MODE" ? 1 : 0
                        property bool selected: false

                        Behavior on opacity {
                            LomiriNumberAnimation{ duration: 500 }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: {
                            root.addNumber(index)
                            mouse.accepted = false
                        }
                    }

                    Behavior on bigR {
                        LomiriNumberAnimation { duration: 500 }
                    }


                    SequentialAnimation {
                        id: anim
                        ParallelAnimation {
                            PropertyAnimation {
                                target: point
                                property: "color"
                                to: d.selected
                                duration: 100
                            }
                            PropertyAnimation {
                                target: selectionRect
                                property: "color"
                                to: d.selectedCircle
                                duration: 100
                            }
                           // ScriptAction {
                           //     script: hapticEffect.start()
                           // }
                        }
                        ParallelAnimation {
                            PropertyAnimation {
                                target: point
                                property: "color"
                                to: d.disabled
                                duration: 400
                            }
                            PropertyAnimation {
                                target: selectionRect
                                property: "color"
                                to: activeAreaVisible ? d.selected : "transparent"
                                duration: 400
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: bottomArea
            Layout.margins: units.gu(2)
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom
            spacing: units.gu(2)

            RowLayout {
                width: parent.width
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    text: i18n.tr("Display pincode")
                    color: d.selected
                }
                Switch {
                    Layout.alignment: Qt.AlignRight
                    onCheckedChanged: root.displayPinCode = checked
                }
            }

            RowLayout {
                width: parent.width
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    text: i18n.tr("Display active area")
                    color: d.selected
                }
                Switch {
                    id: checkboxActive
                    Layout.alignment: Qt.AlignRight
                    onCheckedChanged: activeAreaVisible = checked
                }
            }
        }
    }

    //onStateChanged: root.reset();

    states: [
        State{
            name: "ENTRY_MODE"
            PropertyChanges {
                target: center
                locker: "image://theme/ok"
            }
            PropertyChanges { target: topLabel; text: i18n.tr("Create a pin code") }
            PropertyChanges { target: subtitle; text: i18n.tr("Click or swipe on the digits, click on the circle center to validate") }

            StateChangeScript {
                script: root.reset();
            }
        },
        State {
            name: "EDIT_MODE"
            PropertyChanges { target: topLabel; text: i18n.tr("Current pin") }
            PropertyChanges { target: center; locker: "image://theme/lock" }
            StateChangeScript {
                script: root.reset();
            }
        },
        State {
            name: "TEST_MODE"
            PropertyChanges { target: center; locker: "image://theme/lock" }
            PropertyChanges { target: topLabel; text: i18n.tr("Test your code") }
            PropertyChanges { target: subtitle; text: i18n.tr("Click or swipe on the digits") }
            StateChangeScript {
                script: root.reset();
            }
        },

        State {
            name: "PASSWORD_SUCCESS"
            PropertyChanges { target: subtitle; text: i18n.tr("correct!") }

            PropertyChanges { target: center; locker: "image://theme/reload" }
            PropertyChanges { target: centerImg; color: d.selected }
        }
    ]

    transitions:[
        Transition {
            to: "WRONG_PASSWORD";
            SequentialAnimation {
                PropertyAction { target: subtitle; property: "text"; value: i18n.tr("Wrong code, try again!") }
                PropertyAction { target: center; property: "locker"; value: "image://theme/dialog-warning-symbolic" }
                PauseAnimation { duration: 2000 }
                ScriptAction { script: root.switchToTestMode() }
            }
        },
        Transition {
            to: "PASSWORD_SUCCESS";
            SequentialAnimation {
                PropertyAction { target: subtitle; property: "text"; value: i18n.tr("correct!") }
                PropertyAction { target: center; property: "locker"; value: "image://theme/ok" }
                PauseAnimation { duration: 2000 }
            }
        }
    ]

    Timer {
        running: true
        interval: 400
        onTriggered: {
            if (root.changeMode) {
                root.state = "EDIT_MODE";
            } else {
                root.state = "ENTRY_MODE";
            }


        }
    }
}

