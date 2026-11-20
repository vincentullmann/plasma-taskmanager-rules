#include "launcherprogress.h"

#include <QDBusConnection>

LauncherProgress::LauncherProgress(QObject *parent)
    : QObject(parent)
{
    QDBusConnection::sessionBus().connect(QString(), QString(), QStringLiteral("com.canonical.Unity.LauncherEntry"),
                                          QStringLiteral("Update"), this,
                                          SLOT(onDbusUpdate(QString, QVariantMap)));
}

QVariantMap LauncherProgress::progress(const QString &desktopId) const
{
    const Entry e = m_entries.value(desktopId);
    return {{QStringLiteral("visible"), e.visible}, {QStringLiteral("value"), e.value}};
}

void LauncherProgress::update(const QString &appUri, const QVariantMap &props)
{
    static const QString scheme = QStringLiteral("application://");
    if (!appUri.startsWith(scheme)) return;
    Entry &e = m_entries[appUri.mid(scheme.size())];
    if (props.contains(QStringLiteral("progress-visible"))) e.visible = props.value(QStringLiteral("progress-visible")).toBool();
    if (props.contains(QStringLiteral("progress"))) e.value = props.value(QStringLiteral("progress")).toDouble();
    ++m_revision;
    Q_EMIT changed();
}
