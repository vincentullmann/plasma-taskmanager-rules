#pragma once

#include <QObject>
#include <QHash>
#include <QVariantMap>
#include <QtQml/qqmlregistration.h>

// Download/job progress that apps publish through the com.canonical.Unity.LauncherEntry DBus signal.
// IO only: stores the last Update per desktop file; QML decides how to show it.
class LauncherProgress : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // Bumps on every update so QML bindings that call progress() re-evaluate.
    Q_PROPERTY(int revision READ revision NOTIFY changed)

public:
    explicit LauncherProgress(QObject *parent = nullptr);

    int revision() const { return m_revision; }

    // {visible: bool, value: 0..1} for a desktop file id such as "firefox.desktop"; visible=false if unknown.
    Q_INVOKABLE QVariantMap progress(const QString &desktopId) const;

    // Entry point for the DBus signal; public so tests can drive it without a bus.
    void update(const QString &appUri, const QVariantMap &props);

Q_SIGNALS:
    void changed();

private Q_SLOTS:
    void onDbusUpdate(const QString &appUri, const QVariantMap &props) { update(appUri, props); }

private:
    struct Entry { bool visible = false; double value = 0; };
    QHash<QString, Entry> m_entries;
    int m_revision = 0;
};
