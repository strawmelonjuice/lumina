import * as $charlist from "../../../gleam_erlang/gleam/erlang/charlist.mjs";
import * as $process from "../../../gleam_erlang/gleam/erlang/process.mjs";
import * as $bytes_tree from "../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dynamic from "../../../gleam_stdlib/gleam/dynamic.mjs";
import { toList, CustomType as $CustomType } from "../../gleam.mjs";

export class Closed extends $CustomType {}
export const SocketReason$Closed = () => new Closed();
export const SocketReason$isClosed = (value) => value instanceof Closed;

export class Timeout extends $CustomType {}
export const SocketReason$Timeout = () => new Timeout();
export const SocketReason$isTimeout = (value) => value instanceof Timeout;

export class Badarg extends $CustomType {}
export const SocketReason$Badarg = () => new Badarg();
export const SocketReason$isBadarg = (value) => value instanceof Badarg;

export class Terminated extends $CustomType {}
export const SocketReason$Terminated = () => new Terminated();
export const SocketReason$isTerminated = (value) => value instanceof Terminated;

export class Eaddrinuse extends $CustomType {}
export const SocketReason$Eaddrinuse = () => new Eaddrinuse();
export const SocketReason$isEaddrinuse = (value) => value instanceof Eaddrinuse;

export class Eaddrnotavail extends $CustomType {}
export const SocketReason$Eaddrnotavail = () => new Eaddrnotavail();
export const SocketReason$isEaddrnotavail = (value) =>
  value instanceof Eaddrnotavail;

export class Eafnosupport extends $CustomType {}
export const SocketReason$Eafnosupport = () => new Eafnosupport();
export const SocketReason$isEafnosupport = (value) =>
  value instanceof Eafnosupport;

export class Ealready extends $CustomType {}
export const SocketReason$Ealready = () => new Ealready();
export const SocketReason$isEalready = (value) => value instanceof Ealready;

export class Econnaborted extends $CustomType {}
export const SocketReason$Econnaborted = () => new Econnaborted();
export const SocketReason$isEconnaborted = (value) =>
  value instanceof Econnaborted;

export class Econnrefused extends $CustomType {}
export const SocketReason$Econnrefused = () => new Econnrefused();
export const SocketReason$isEconnrefused = (value) =>
  value instanceof Econnrefused;

export class Econnreset extends $CustomType {}
export const SocketReason$Econnreset = () => new Econnreset();
export const SocketReason$isEconnreset = (value) => value instanceof Econnreset;

export class Edestaddrreq extends $CustomType {}
export const SocketReason$Edestaddrreq = () => new Edestaddrreq();
export const SocketReason$isEdestaddrreq = (value) =>
  value instanceof Edestaddrreq;

export class Ehostdown extends $CustomType {}
export const SocketReason$Ehostdown = () => new Ehostdown();
export const SocketReason$isEhostdown = (value) => value instanceof Ehostdown;

export class Ehostunreach extends $CustomType {}
export const SocketReason$Ehostunreach = () => new Ehostunreach();
export const SocketReason$isEhostunreach = (value) =>
  value instanceof Ehostunreach;

export class Einprogress extends $CustomType {}
export const SocketReason$Einprogress = () => new Einprogress();
export const SocketReason$isEinprogress = (value) =>
  value instanceof Einprogress;

export class Eisconn extends $CustomType {}
export const SocketReason$Eisconn = () => new Eisconn();
export const SocketReason$isEisconn = (value) => value instanceof Eisconn;

export class Emsgsize extends $CustomType {}
export const SocketReason$Emsgsize = () => new Emsgsize();
export const SocketReason$isEmsgsize = (value) => value instanceof Emsgsize;

export class Enetdown extends $CustomType {}
export const SocketReason$Enetdown = () => new Enetdown();
export const SocketReason$isEnetdown = (value) => value instanceof Enetdown;

export class Enetunreach extends $CustomType {}
export const SocketReason$Enetunreach = () => new Enetunreach();
export const SocketReason$isEnetunreach = (value) =>
  value instanceof Enetunreach;

export class Enopkg extends $CustomType {}
export const SocketReason$Enopkg = () => new Enopkg();
export const SocketReason$isEnopkg = (value) => value instanceof Enopkg;

export class Enoprotoopt extends $CustomType {}
export const SocketReason$Enoprotoopt = () => new Enoprotoopt();
export const SocketReason$isEnoprotoopt = (value) =>
  value instanceof Enoprotoopt;

export class Enotconn extends $CustomType {}
export const SocketReason$Enotconn = () => new Enotconn();
export const SocketReason$isEnotconn = (value) => value instanceof Enotconn;

export class Enotty extends $CustomType {}
export const SocketReason$Enotty = () => new Enotty();
export const SocketReason$isEnotty = (value) => value instanceof Enotty;

export class Enotsock extends $CustomType {}
export const SocketReason$Enotsock = () => new Enotsock();
export const SocketReason$isEnotsock = (value) => value instanceof Enotsock;

export class Eproto extends $CustomType {}
export const SocketReason$Eproto = () => new Eproto();
export const SocketReason$isEproto = (value) => value instanceof Eproto;

export class Eprotonosupport extends $CustomType {}
export const SocketReason$Eprotonosupport = () => new Eprotonosupport();
export const SocketReason$isEprotonosupport = (value) =>
  value instanceof Eprotonosupport;

export class Eprototype extends $CustomType {}
export const SocketReason$Eprototype = () => new Eprototype();
export const SocketReason$isEprototype = (value) => value instanceof Eprototype;

export class Esocktnosupport extends $CustomType {}
export const SocketReason$Esocktnosupport = () => new Esocktnosupport();
export const SocketReason$isEsocktnosupport = (value) =>
  value instanceof Esocktnosupport;

export class Etimedout extends $CustomType {}
export const SocketReason$Etimedout = () => new Etimedout();
export const SocketReason$isEtimedout = (value) => value instanceof Etimedout;

export class Ewouldblock extends $CustomType {}
export const SocketReason$Ewouldblock = () => new Ewouldblock();
export const SocketReason$isEwouldblock = (value) =>
  value instanceof Ewouldblock;

export class Exbadport extends $CustomType {}
export const SocketReason$Exbadport = () => new Exbadport();
export const SocketReason$isExbadport = (value) => value instanceof Exbadport;

export class Exbadseq extends $CustomType {}
export const SocketReason$Exbadseq = () => new Exbadseq();
export const SocketReason$isExbadseq = (value) => value instanceof Exbadseq;

export class Read extends $CustomType {}
export const Shutdown$Read = () => new Read();
export const Shutdown$isRead = (value) => value instanceof Read;

export class Write extends $CustomType {}
export const Shutdown$Write = () => new Write();
export const Shutdown$isWrite = (value) => value instanceof Write;

export class ReadWrite extends $CustomType {}
export const Shutdown$ReadWrite = () => new ReadWrite();
export const Shutdown$isReadWrite = (value) => value instanceof ReadWrite;

export class Once extends $CustomType {}
export const ActiveMode$Once = () => new Once();
export const ActiveMode$isOnce = (value) => value instanceof Once;

export class Passive extends $CustomType {}
export const ActiveMode$Passive = () => new Passive();
export const ActiveMode$isPassive = (value) => value instanceof Passive;

export class Count extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const ActiveMode$Count = ($0) => new Count($0);
export const ActiveMode$isCount = (value) => value instanceof Count;
export const ActiveMode$Count$0 = (value) => value[0];

export class Active extends $CustomType {}
export const ActiveMode$Active = () => new Active();
export const ActiveMode$isActive = (value) => value instanceof Active;

export class Binary extends $CustomType {}
export const PacketMode$Binary = () => new Binary();
export const PacketMode$isBinary = (value) => value instanceof Binary;

export class VerifyPeer extends $CustomType {}
export const VerifyMode$VerifyPeer = () => new VerifyPeer();
export const VerifyMode$isVerifyPeer = (value) => value instanceof VerifyPeer;

export class VerifyNone extends $CustomType {}
export const VerifyMode$VerifyNone = () => new VerifyNone();
export const VerifyMode$isVerifyNone = (value) => value instanceof VerifyNone;

export class ActiveMode extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$ActiveMode = ($0) => new ActiveMode($0);
export const Option$isActiveMode = (value) => value instanceof ActiveMode;
export const Option$ActiveMode$0 = (value) => value[0];

export class Mode extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$Mode = ($0) => new Mode($0);
export const Option$isMode = (value) => value instanceof Mode;
export const Option$Mode$0 = (value) => value[0];

/**
 * In milliseconds.
 */
export class SendTimeout extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$SendTimeout = ($0) => new SendTimeout($0);
export const Option$isSendTimeout = (value) => value instanceof SendTimeout;
export const Option$SendTimeout$0 = (value) => value[0];

export class SendTimeoutClose extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$SendTimeoutClose = ($0) => new SendTimeoutClose($0);
export const Option$isSendTimeoutClose = (value) =>
  value instanceof SendTimeoutClose;
export const Option$SendTimeoutClose$0 = (value) => value[0];

export class Reuseaddr extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$Reuseaddr = ($0) => new Reuseaddr($0);
export const Option$isReuseaddr = (value) => value instanceof Reuseaddr;
export const Option$Reuseaddr$0 = (value) => value[0];

/**
 * Disable Nagle's algorithm.
 */
export class Nodelay extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$Nodelay = ($0) => new Nodelay($0);
export const Option$isNodelay = (value) => value instanceof Nodelay;
export const Option$Nodelay$0 = (value) => value[0];

export class Verify extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$Verify = ($0) => new Verify($0);
export const Option$isVerify = (value) => value instanceof Verify;
export const Option$Verify$0 = (value) => value[0];

export class Cacerts extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$Cacerts = ($0) => new Cacerts($0);
export const Option$isCacerts = (value) => value instanceof Cacerts;
export const Option$Cacerts$0 = (value) => value[0];

export class CustomizeHostnameCheck extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$CustomizeHostnameCheck = ($0) =>
  new CustomizeHostnameCheck($0);
export const Option$isCustomizeHostnameCheck = (value) =>
  value instanceof CustomizeHostnameCheck;
export const Option$CustomizeHostnameCheck$0 = (value) => value[0];

export class ServerNameIndication extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const Option$ServerNameIndication = ($0) => new ServerNameIndication($0);
export const Option$isServerNameIndication = (value) =>
  value instanceof ServerNameIndication;
export const Option$ServerNameIndication$0 = (value) => value[0];

export class Tcp extends $CustomType {}
export const Transport$Tcp = () => new Tcp();
export const Transport$isTcp = (value) => value instanceof Tcp;

export class Ssl extends $CustomType {}
export const Transport$Ssl = () => new Ssl();
export const Transport$isSsl = (value) => value instanceof Ssl;

/**
 * Default options for a WebSocket client.
 */
export const default_options = /* @__PURE__ */ toList([
  /* @__PURE__ */ new ActiveMode(/* @__PURE__ */ new Passive()),
  /* @__PURE__ */ new Mode(/* @__PURE__ */ new Binary()),
  /* @__PURE__ */ new SendTimeout(30_000),
  /* @__PURE__ */ new SendTimeoutClose(true),
  /* @__PURE__ */ new Reuseaddr(true),
  /* @__PURE__ */ new Nodelay(true),
]);

/**
 * Convert a socket error reason to a human-readable string.
 */
export function reason_to_string(reason) {
  if (reason instanceof Closed) {
    return "connection closed";
  } else if (reason instanceof Timeout) {
    return "operation timed out";
  } else if (reason instanceof Badarg) {
    return "bad argument";
  } else if (reason instanceof Terminated) {
    return "process terminated";
  } else if (reason instanceof Eaddrinuse) {
    return "address already in use";
  } else if (reason instanceof Eaddrnotavail) {
    return "address not available";
  } else if (reason instanceof Eafnosupport) {
    return "address family not supported";
  } else if (reason instanceof Ealready) {
    return "operation already in progress";
  } else if (reason instanceof Econnaborted) {
    return "connection aborted";
  } else if (reason instanceof Econnrefused) {
    return "connection refused";
  } else if (reason instanceof Econnreset) {
    return "connection reset by peer";
  } else if (reason instanceof Edestaddrreq) {
    return "destination address required";
  } else if (reason instanceof Ehostdown) {
    return "host is down";
  } else if (reason instanceof Ehostunreach) {
    return "host is unreachable";
  } else if (reason instanceof Einprogress) {
    return "operation in progress";
  } else if (reason instanceof Eisconn) {
    return "already connected";
  } else if (reason instanceof Emsgsize) {
    return "message too long";
  } else if (reason instanceof Enetdown) {
    return "network is down";
  } else if (reason instanceof Enetunreach) {
    return "network is unreachable";
  } else if (reason instanceof Enopkg) {
    return "package not installed";
  } else if (reason instanceof Enoprotoopt) {
    return "protocol not available";
  } else if (reason instanceof Enotconn) {
    return "not connected";
  } else if (reason instanceof Enotty) {
    return "inappropriate ioctl for device";
  } else if (reason instanceof Enotsock) {
    return "not a socket";
  } else if (reason instanceof Eproto) {
    return "protocol error";
  } else if (reason instanceof Eprotonosupport) {
    return "protocol not supported";
  } else if (reason instanceof Eprototype) {
    return "wrong protocol type for socket";
  } else if (reason instanceof Esocktnosupport) {
    return "socket type not supported";
  } else if (reason instanceof Etimedout) {
    return "connection timed out";
  } else if (reason instanceof Ewouldblock) {
    return "operation would block";
  } else if (reason instanceof Exbadport) {
    return "bad port";
  } else {
    return "bad sequence";
  }
}
