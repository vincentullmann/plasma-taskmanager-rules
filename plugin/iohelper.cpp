#include "iohelper.h"

#include <QDir>
#include <QFileInfo>
#include <QSaveFile>

IoHelper::IoHelper(QObject *parent)
    : QObject(parent)
{
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(50);
    connect(&m_debounce, &QTimer::timeout, this, [this] {
        rearm();
        Q_EMIT fileChanged(m_path);
    });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &IoHelper::onPathEvent);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &IoHelper::onPathEvent);
}

QString IoHelper::expandPath(const QString &path) const
{
    if (path == QLatin1String("~") || path.startsWith(QLatin1String("~/"))) {
        return QDir::homePath() + path.mid(1);
    }
    return path;
}

void IoHelper::watch(const QString &path)
{
    unwatch();
    m_path = expandPath(path);
    rearm();
}

void IoHelper::unwatch()
{
    const auto files = m_watcher.files();
    const auto dirs = m_watcher.directories();
    if (!files.isEmpty()) m_watcher.removePaths(files);
    if (!dirs.isEmpty()) m_watcher.removePaths(dirs);
    m_path.clear();
}

// Atomic saves replace the inode, which silently drops the file watch. Watch the parent
// directory too (catches create/rename/delete) and re-add the file watch after each event.
void IoHelper::rearm()
{
    if (m_path.isEmpty()) return;
    const QString dir = QFileInfo(m_path).absolutePath();
    if (!m_watcher.directories().contains(dir) && QFileInfo(dir).isDir()) {
        m_watcher.addPath(dir);
    }
    if (!m_watcher.files().contains(m_path) && QFileInfo::exists(m_path)) {
        m_watcher.addPath(m_path);
    }
}

void IoHelper::onPathEvent()
{
    // Debounce: an atomic save produces several events in a burst.
    m_debounce.start();
}

bool IoHelper::exists(const QString &path) const
{
    return QFileInfo::exists(expandPath(path));
}

QString IoHelper::readFile(const QString &path) const
{
    QFile f(expandPath(path));
    if (!f.open(QIODevice::ReadOnly)) return {};
    return QString::fromUtf8(f.readAll());
}

bool IoHelper::writeFile(const QString &path, const QString &text) const
{
    const QString p = expandPath(path);
    if (!QDir().mkpath(QFileInfo(p).absolutePath())) return false;
    QSaveFile f(p);
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write(text.toUtf8());
    return f.commit();
}

QString IoHelper::exePath(qint64 pid)
{
    if (pid <= 0) return {};
    if (const auto it = m_exeCache.constFind(pid); it != m_exeCache.constEnd()) return *it;
    const QString target = QFileInfo(QStringLiteral("/proc/%1/exe").arg(pid)).symLinkTarget();
    // Only cache successes: a PID can be queried before its exe is readable.
    if (!target.isEmpty()) m_exeCache.insert(pid, target);
    return target;
}
