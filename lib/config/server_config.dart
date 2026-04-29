/// Remote server connection settings for the nfc-login-server.
///
/// Must point at the same `nfc-login-server` instance the Pi connects to,
/// i.e. whatever you set as `RemoteServer` / `RemoteServerPort` in the Pi's
/// `cpp-senior-design.conf`. Phone and Pi both speak directly to this server;
/// they never talk to each other.
const String kDefaultServerHost = '100.112.38.47';
const int kDefaultServerPort = 5001;
