#pragma once

#include <QObject>
#include <QFileSystemWatcher>
#include <QHash>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

// IO-only helper exposed to QML. No matching/merge logic lives here.
class IoHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit IoHelper(QObject *parent = nullptr);

    // Watch a file; survives atomic saves (rename-over) and deletion/re-creation.
    Q_INVOKABLE void watch(const QString &path);
    Q_INVOKABLE void unwatch();

    Q_INVOKABLE bool exists(const QString &path) const;
    Q_INVOKABLE QString readFile(const QString &path) const;
    // Atomic (QSaveFile); creates parent directories.
    Q_INVOKABLE bool writeFile(const QString &path, const QString &text) const;
    // Replaces a leading "~" with the home directory.
    Q_INVOKABLE QString expandPath(const QString &path) const;
    // readlink /proc/<pid>/exe, cached per PID. Empty if unresolvable.
    Q_INVOKABLE QString exePath(qint64 pid);

    int exeCacheSize() const { return m_exeCache.size(); }

Q_SIGNALS:
    void fileChanged(const QString &path);

private:
    void rearm();
    void onPathEvent();

    QString m_path;
    QFileSystemWatcher m_watcher;
    QTimer m_debounce;
    QHash<qint64, QString> m_exeCache;
};
