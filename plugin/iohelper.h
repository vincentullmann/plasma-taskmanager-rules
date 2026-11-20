#pragma once

#include <QObject>
#include <QtQml/qqmlregistration.h>

// IO-only helper exposed to QML. Filled in by the "C++ IO helper plugin" ticket.
class IoHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit IoHelper(QObject *parent = nullptr);
};
