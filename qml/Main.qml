/*
 * Copyright (C) 2022  Your FullName
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * unlockertest is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'unlockertest.ld'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

//    SchemaPinPromptTutorialNoDots {

//    }

    Page {
        id: home
        anchors.fill: parent

        header: PageHeader {
            id: header
            title: i18n.tr('Pin-code clock unlocker tester')
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: header.bottom
            anchors.bottom: btn.top
            width: units.gu(40)
            text: i18n.tr('This is a tester for the "clock" pin-code prompt')
            elide: Label.ElideRight

            verticalAlignment: Label.AlignVCenter
            horizontalAlignment: Label.AlignHCenter
        }

        Button {
            id: btn
            anchors.centerIn: parent
            text: i18n.tr("OK")
            onTriggered: pageStack.push(Qt.resolvedUrl("SchemaPinPromptTutorialNoDots.qml"))
        }
    }

    PageStack {
        id: pageStack
        anchors.fill: parent
        currentPage: home
    }
}
