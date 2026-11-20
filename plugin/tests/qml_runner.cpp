// Minimal headless runner: loads a QML file, exits with the code given to Qt.exit().
// Unlike `qml6`, it prints load errors. Any QML warning (binding errors, undefined access) fails
// the run with exit code 4, so tests catch broken bindings as well as broken logic.
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <QDebug>
#include <KLocalizedContext>
#include <KLocalizedString>

static bool s_sawWarning = false;
static QtMessageHandler s_prev = nullptr;

static void handler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    if (type == QtWarningMsg || type == QtCriticalMsg) {
        s_sawWarning = true;
    }
    s_prev(type, ctx, msg);
}

int main(int argc, char **argv)
{
    qputenv("QT_FORCE_STDERR_LOGGING", "1");
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");
    QGuiApplication app(argc, argv);
    const QStringList args = app.arguments();
    if (args.size() < 3) {
        qCritical() << "usage: qml_runner <import-path> <file.qml>";
        return 2;
    }
    KLocalizedString::setApplicationDomain("tmrules-tests");
    s_prev = qInstallMessageHandler(handler);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.addImportPath(args.at(1));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(3); }, Qt::QueuedConnection);
    engine.load(QUrl::fromLocalFile(args.at(2)));
    // QQmlApplicationEngine already routes Qt.exit(code) to QCoreApplication::exit(code).
    const int code = app.exec();
    return code == 0 && s_sawWarning ? 4 : code;
}
