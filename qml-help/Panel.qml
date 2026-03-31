import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root
    property var pluginApi: null
    
    property var categories: pluginApi ? pluginApi.pluginSettings?.categories || [] : []
    
    property real contentPreferredWidth: 1400
    property real contentPreferredHeight: 800
    
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: false 
    readonly property bool panelAnchorHorizontalCenter: true
    readonly property bool panelAnchorVerticalCenter: true
    anchors.fill: parent
    
    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: Color.mSurface
        radius: Style.radiusL
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginM
            
            // Вкладки категорий
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"
                
                ScrollView {
                    anchors.fill: parent
                    contentWidth: tabsRow.width
                    clip: true
                    
                    Row {
                        id: tabsRow
                        height: parent.height
                        spacing: Style.marginS
                        
                        Repeater {
                            model: categories
                            
                            Rectangle {
                                id: tabButton
                                height: 50
                                width: Math.min(200, tabText.implicitWidth + 60)
                                radius: 10
                                color: tabBar.currentIndex === index ? Color.mPrimary : Color.mSurfaceVariant
                                border.width: 1
                                border.color: tabBar.currentIndex === index ? Color.mPrimary : Color.mOutline
                                
                                property bool isCurrent: tabBar.currentIndex === index
                                
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    
                                    NIcon {
                                        icon: modelData.icon || "help"
                                        pointSize: 18
                                        color: tabButton.isCurrent ? Color.mOnPrimary : Color.mOnSurface
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    NText {
                                        id: tabText
                                        text: modelData.title || `Категория ${index + 1}`
                                        color: tabButton.isCurrent ? Color.mOnPrimary : Color.mOnSurface
                                        font.pointSize: Style.fontSizeM
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: tabBar.currentIndex = index
                                }
                                
                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    height: 3
                                    color: Color.mSecondary
                                    radius: 1.5
                                    visible: tabButton.isCurrent
                                }
                            }
                        }
                    }
                }
            }
            
            // Разделитель
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Color.mOutline
                opacity: 0.3
            }
            
            // Основное содержимое
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Style.marginM
                
                // Левая панель с элементами категории
                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.fillHeight: true
                    color: Color.mSurfaceVariant
                    radius: 12
                    border.width: 1
                    border.color: Color.mOutline
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        // Заголовок списка элементов
                        Rectangle {
                            width: parent.width
                            height: 40
                            color: "transparent"
                            
                            NText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Элементы"
                                font.pointSize: Style.fontSizeL
                                font.weight: Font.Bold
                                color: Color.mPrimary
                            }
                            
                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: 1
                                color: Color.mOutline
                                opacity: 0.3
                            }
                        }
                        
                        // Список элементов
                        ScrollView {
                            width: parent.width
                            height: parent.height - 60
                            
                            ListView {
                                id: itemsList
                                width: parent.width
                                model: categories.length > 0 && categories[tabBar.currentIndex]?.items ? 
                                       categories[tabBar.currentIndex].items : []
                                spacing: 6
                                clip: true
                                
                                delegate: Rectangle {
                                    id: itemDelegate
                                    width: itemsList.width
                                    height: 48
                                    radius: 8
                                    color: itemsList.currentIndex === index ? Color.mPrimary : 
                                           mouseArea.containsMouse ? Color.mHover : "transparent"
                                    border.width: 1
                                    border.color: itemsList.currentIndex === index ? Color.mPrimary : 
                                                 mouseArea.containsMouse ? Color.mHover : Color.mOutline
                                    
                                    property bool isSelected: itemsList.currentIndex === index
                                    
                                    Row {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10
                                        
                                        // Индикатор выбранного элемента
                                        Rectangle {
                                            width: 4
                                            height: 20
                                            radius: 2
                                            color: Color.mSecondary
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: itemDelegate.isSelected
                                        }
                                        
                                        // Название элемента
                                        NText {
                                            text: modelData.title || `Элемент ${index + 1}`
                                            color: itemDelegate.isSelected ? Color.mOnPrimary : 
                                                   mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                                            font.pointSize: Style.fontSizeM
                                            font.weight: itemDelegate.isSelected ? Font.Bold : Font.Normal
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 30
                                            elide: Text.ElideRight
                                            maximumLineCount: 2
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: itemsList.currentIndex = index
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Правая панель с примером
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Color.mSurfaceVariant
                    radius: 12
                    border.width: 1
                    border.color: Color.mOutline
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM
                        
                        // Заголовок примера
                        Column {
                            width: parent.width
                            spacing: 4
                            
                            NText {
                                width: parent.width
                                text: itemsList.currentIndex >= 0 && itemsList.model[itemsList.currentIndex]?.title ? 
                                      itemsList.model[itemsList.currentIndex].title : "Выберите элемент"
                                font.pointSize: Style.fontSizeL
                                font.weight: Font.Bold
                                color: Color.mPrimary
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            
                            NText {
                                width: parent.width
                                text: itemsList.currentIndex >= 0 && itemsList.model[itemsList.currentIndex]?.description ? 
                                      itemsList.model[itemsList.currentIndex].description : "Описание появится здесь"
                                font.pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                            
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Color.mOutline
                                opacity: 0.3
                            }
                        }
                        
                        // Поле с примером кода
                        Rectangle {
                            width: parent.width
                            height: parent.height - 100
                            color: Color.mSurface
                            radius: 8
                            border.width: 1
                            border.color: Color.mOutline
                            
                            Flickable {
                                id: codeFlickable
                                anchors.fill: parent
                                anchors.margins: 2
                                contentWidth: codeText.width
                                contentHeight: codeText.height
                                clip: true
                                
                                TextEdit {
                                    id: codeText
                                    text: itemsList.currentIndex >= 0 && itemsList.model[itemsList.currentIndex]?.example ? 
                                          itemsList.model[itemsList.currentIndex].example : "// Пример кода появится здесь"
                                    font.family: "Monospace"
                                    font.pixelSize: 16
                                    color: Color.mOnSurface
                                    readOnly: true
                                    wrapMode: Text.NoWrap
                                    selectByMouse: true
                                    padding: 12
                                }
                                
                                ScrollBar.horizontal: ScrollBar {
                                    policy: codeText.width > codeFlickable.width ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                                }
                                
                                ScrollBar.vertical: ScrollBar {
                                    policy: codeText.height > codeFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                                }
                            }
                            
                            // // Статусная строка
                            // Rectangle {
                            //     anchors {
                            //         left: parent.left
                            //         right: parent.right
                            //         bottom: parent.bottom
                            //     }
                            //     height: 28
                            //     color: Color.mSurfaceVariant
                            //     border.width: 1
                            //     border.color: Color.mOutline
                                
                            //     Row {
                            //         anchors.fill: parent
                            //         anchors.margins: 6
                            //         spacing: 12
                                    
                            //         NText {
                            //             text: "QML"
                            //             color: Color.mOnSurfaceVariant
                            //             font.pointSize: Style.fontSizeXS
                            //             anchors.verticalCenter: parent.verticalCenter
                            //         }
                                    
                            //         Rectangle {
                            //             width: 1
                            //             height: 14
                            //             color: Color.mOutline
                            //             opacity: 0.3
                            //             anchors.verticalCenter: parent.verticalCenter
                            //         }
                                    
                            //         NText {
                            //             text: itemsList.currentIndex >= 0 ? `Строк: ${codeText.lineCount}` : "Строк: 0"
                            //             color: Color.mOnSurfaceVariant
                            //             font.pointSize: Style.fontSizeXS
                            //             anchors.verticalCenter: parent.verticalCenter
                            //         }
                                    
                            //         Rectangle {
                            //             width: 1
                            //             height: 14
                            //             color: Color.mOutline
                            //             opacity: 0.3
                            //             anchors.verticalCenter: parent.verticalCenter
                            //         }
                                    
                            //         NText {
                            //             text: itemsList.currentIndex >= 0 ? `Символов: ${codeText.length}` : "Символов: 0"
                            //             color: Color.mOnSurfaceVariant
                            //             font.pointSize: Style.fontSizeXS
                            //             anchors.verticalCenter: parent.verticalCenter
                            //         }
                            //     }
                            // }
                        }
                        
                        // Подсказка
                        // Rectangle {
                        //     width: parent.width
                        //     height: 28
                        //     color: Color.mPrimary
                        //     opacity: 0.1
                        //     radius: 6
                        //     visible: itemsList.currentIndex < 0
                            
                        //     Row {
                        //         anchors.centerIn: parent
                        //         spacing: 6
                                
                        //         NIcon {
                        //             icon: "info"
                        //             pointSize: 14
                        //             color: Color.mPrimary
                        //             anchors.verticalCenter: parent.verticalCenter
                        //         }
                                
                        //         NText {
                        //             text: "Выберите элемент из списка слева для просмотра примера"
                        //             color: Color.mPrimary
                        //             font.pointSize: Style.fontSizeXS
                        //             anchors.verticalCenter: parent.verticalCenter
                        //         }
                        //     }
                        // }
                    }
                }
            }
        }
    }
    
    // Скрытый TabBar для управления состоянием
    TabBar {
        id: tabBar
        visible: false
        currentIndex: 0
    }
}
