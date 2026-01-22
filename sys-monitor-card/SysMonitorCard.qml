import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Services.UI
import qs.Widgets

NBox {
    id: root
    
    readonly property string diskPath: Settings.data.controlCenter.diskPath || "/"
    readonly property real contentScale: 0.95 * Style.uiScaleRatio
    readonly property real barSpacing: 8 * Style.uiScaleRatio
    readonly property real cardPadding: 12 * Style.uiScaleRatio
    readonly property real iconBorderWidth: 1 * Style.uiScaleRatio
    readonly property real columnBorderWidth: 1 * Style.uiScaleRatio
    readonly property real columnBorderRadius: 8 * Style.uiScaleRatio
    readonly property real segmentBorderWidth: 0.5 * Style.uiScaleRatio
    
    // Функции для вычисления цветов на основе значений
    function getColor(usage) {
        if (usage < 50) return Color.mPrimary 
        if (usage < 75) return Color.mHover  
        return "red" 
    }

    function getTempColor(temp) {
        if (temp < 40) return Color.mPrimary
        if (temp < 80) return Color.mHover
        return "red"
    }
    
    // Компонент сегментного индикатора
    component SegmentIndicator: Item {
        id: segmentIndicator
        
        // Свойства
        required property real value
        required property string metricName
        required property color activeColor
        property string unit: "%"
        property bool showUnit: true
        property int segmentCount: 10  // Количество сегментов
        property real segmentHeight: 8 * Style.uiScaleRatio
        property real segmentSpacing: 2 * Style.uiScaleRatio
        property real segmentWidthRatio: 0.8  // Ширина относительно родителя
        property real iconSize: 24 * Style.uiScaleRatio
        property real iconBorderRadius: 6 * Style.uiScaleRatio
        
        width: parent ? parent.width : 100
        height: parent ? parent.height : 100
        
        Rectangle {
            id: columnBorder
            anchors.fill: parent
            radius: columnBorderRadius
            color: Color.mSurface
            border.width: columnBorderWidth
            border.color: Color.mOutline
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 8 * Style.uiScaleRatio
            spacing: 6 * Style.uiScaleRatio
            
            Item {
                width: parent.width
                height: iconSize + 10 * Style.uiScaleRatio
                
                Rectangle {
                    id: iconBorder
                    width: iconSize + 8 * Style.uiScaleRatio
                    height: iconSize + 8 * Style.uiScaleRatio
                    radius: iconBorderRadius
                    color: Color.mPrimary
                    border.width: iconBorderWidth
                    border.color: Color.mShadow
                    anchors.centerIn: parent
                }
                
                NIcon {
                    anchors.centerIn: parent
                    icon: segmentIndicator.metricName
                    pointSize: 16 
                    color: Color.mOnPrimary
                }
            }
            
            Column {
                width: parent.width
                height: (segmentIndicator.segmentHeight * segmentIndicator.segmentCount) + 
                       (segmentIndicator.segmentSpacing * (segmentIndicator.segmentCount - 1))
                spacing: segmentIndicator.segmentSpacing
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Сегменты в обратном порядке (сверху вниз)
                Repeater {
                    model: segmentIndicator.segmentCount
                    
                    Item {
                        width: parent.width * segmentIndicator.segmentWidthRatio
                        height: segmentIndicator.segmentHeight
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        property real segmentThreshold: 100 - ((model.index + 1) * (100 / segmentIndicator.segmentCount))
                        property bool isActive: segmentIndicator.value >= segmentThreshold
                        
                        // Фон сегмента
                        Rectangle {
                            id: segmentBackground
                            anchors.fill: parent
                            radius: 2
                            color: isActive ? segmentIndicator.activeColor : Color.mSurfaceVariant
                            opacity: isActive ? 1 : 0.5
                        }
                        
                        // Для неактивных сегментов
                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: Color.mOutline
                            opacity: isActive ? 0 : 1
                        }
                    }
                }
            }
            
            Text {
                width: parent.width
                text: segmentIndicator.showUnit ? 
                      `${Math.round(segmentIndicator.value)}${segmentIndicator.unit}` : 
                      `${Math.round(segmentIndicator.value)}`
                font.pixelSize: 12 * Style.uiScaleRatio
                font.bold: true
                color: segmentIndicator.activeColor
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    
    // Контент карточки с сегментными индикаторами
    RowLayout {
        anchors.fill: parent
        anchors.margins: cardPadding
        spacing: barSpacing * 1.5
        
        // CPU Usage
        SegmentIndicator {
            Layout.fillHeight: true
            Layout.fillWidth: true
            value: SystemStatService.cpuUsage
            metricName: "cpu-usage"
            activeColor: getColor(SystemStatService.cpuUsage)
            unit: "%"
            showUnit: true
            segmentCount: 10  
        }
        
        // Memory Usage
        SegmentIndicator {
            Layout.fillHeight: true
            Layout.fillWidth: true
            value: SystemStatService.memPercent
            metricName: "memory"
            activeColor: getColor(SystemStatService.memPercent)
            unit: "%"
            showUnit: true
            segmentCount: 10 
        }
        
        // Disk Usage
        SegmentIndicator {
            Layout.fillHeight: true
            Layout.fillWidth: true
            value: SystemStatService.diskPercents[root.diskPath] || 0
            metricName: "storage"
            activeColor: getColor(SystemStatService.diskPercents[root.diskPath] || 0)
            unit: "%"
            showUnit: true
            segmentCount: 10  
        }

        // CPU Temperature
        SegmentIndicator {
            Layout.fillHeight: true
            Layout.fillWidth: true
            value: SystemStatService.cpuTemp || 20
            metricName: "cpu-temperature"
            activeColor: getTempColor(SystemStatService.cpuTemp)
            unit: "°"
            showUnit: true
            segmentCount: 10  
        }
    }
}