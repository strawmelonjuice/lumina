import * as $decode from "../gleam_stdlib/gleam/dynamic/decode.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";
import * as $option from "../gleam_stdlib/gleam/option.mjs";
import { None, Some } from "../gleam_stdlib/gleam/option.mjs";
import * as $result from "../gleam_stdlib/gleam/result.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";
import { Ok, Empty as $Empty, CustomType as $CustomType, makeError } from "./gleam.mjs";
import {
  open as open_,
  close as close_,
  query as run_query,
  coerce_value,
  exec as exec_,
  coerce_blob as blob,
  null_ as null$,
} from "./sqlight_ffi.js";

export { blob, null$ };

const FILEPATH = "src/sqlight.gleam";

export class Stats extends $CustomType {
  constructor(used, highwater) {
    super();
    this.used = used;
    this.highwater = highwater;
  }
}
export const Stats$Stats = (used, highwater) => new Stats(used, highwater);
export const Stats$isStats = (value) => value instanceof Stats;
export const Stats$Stats$used = (value) => value.used;
export const Stats$Stats$0 = (value) => value.used;
export const Stats$Stats$highwater = (value) => value.highwater;
export const Stats$Stats$1 = (value) => value.highwater;

export class SqlightError extends $CustomType {
  constructor(code, message, offset) {
    super();
    this.code = code;
    this.message = message;
    this.offset = offset;
  }
}
export const Error$SqlightError = (code, message, offset) =>
  new SqlightError(code, message, offset);
export const Error$isSqlightError = (value) => value instanceof SqlightError;
export const Error$SqlightError$code = (value) => value.code;
export const Error$SqlightError$0 = (value) => value.code;
export const Error$SqlightError$message = (value) => value.message;
export const Error$SqlightError$1 = (value) => value.message;
export const Error$SqlightError$offset = (value) => value.offset;
export const Error$SqlightError$2 = (value) => value.offset;

export class Abort extends $CustomType {}
export const ErrorCode$Abort = () => new Abort();
export const ErrorCode$isAbort = (value) => value instanceof Abort;

export class Auth extends $CustomType {}
export const ErrorCode$Auth = () => new Auth();
export const ErrorCode$isAuth = (value) => value instanceof Auth;

export class Busy extends $CustomType {}
export const ErrorCode$Busy = () => new Busy();
export const ErrorCode$isBusy = (value) => value instanceof Busy;

export class Cantopen extends $CustomType {}
export const ErrorCode$Cantopen = () => new Cantopen();
export const ErrorCode$isCantopen = (value) => value instanceof Cantopen;

export class Constraint extends $CustomType {}
export const ErrorCode$Constraint = () => new Constraint();
export const ErrorCode$isConstraint = (value) => value instanceof Constraint;

export class Corrupt extends $CustomType {}
export const ErrorCode$Corrupt = () => new Corrupt();
export const ErrorCode$isCorrupt = (value) => value instanceof Corrupt;

export class Done extends $CustomType {}
export const ErrorCode$Done = () => new Done();
export const ErrorCode$isDone = (value) => value instanceof Done;

export class Empty extends $CustomType {}
export const ErrorCode$Empty = () => new Empty();
export const ErrorCode$isEmpty = (value) => value instanceof Empty;

export class GenericError extends $CustomType {}
export const ErrorCode$GenericError = () => new GenericError();
export const ErrorCode$isGenericError = (value) =>
  value instanceof GenericError;

export class Format extends $CustomType {}
export const ErrorCode$Format = () => new Format();
export const ErrorCode$isFormat = (value) => value instanceof Format;

export class Full extends $CustomType {}
export const ErrorCode$Full = () => new Full();
export const ErrorCode$isFull = (value) => value instanceof Full;

export class Internal extends $CustomType {}
export const ErrorCode$Internal = () => new Internal();
export const ErrorCode$isInternal = (value) => value instanceof Internal;

export class Interrupt extends $CustomType {}
export const ErrorCode$Interrupt = () => new Interrupt();
export const ErrorCode$isInterrupt = (value) => value instanceof Interrupt;

export class Ioerr extends $CustomType {}
export const ErrorCode$Ioerr = () => new Ioerr();
export const ErrorCode$isIoerr = (value) => value instanceof Ioerr;

export class Locked extends $CustomType {}
export const ErrorCode$Locked = () => new Locked();
export const ErrorCode$isLocked = (value) => value instanceof Locked;

export class Mismatch extends $CustomType {}
export const ErrorCode$Mismatch = () => new Mismatch();
export const ErrorCode$isMismatch = (value) => value instanceof Mismatch;

export class Misuse extends $CustomType {}
export const ErrorCode$Misuse = () => new Misuse();
export const ErrorCode$isMisuse = (value) => value instanceof Misuse;

export class Nolfs extends $CustomType {}
export const ErrorCode$Nolfs = () => new Nolfs();
export const ErrorCode$isNolfs = (value) => value instanceof Nolfs;

export class Nomem extends $CustomType {}
export const ErrorCode$Nomem = () => new Nomem();
export const ErrorCode$isNomem = (value) => value instanceof Nomem;

export class Notadb extends $CustomType {}
export const ErrorCode$Notadb = () => new Notadb();
export const ErrorCode$isNotadb = (value) => value instanceof Notadb;

export class Notfound extends $CustomType {}
export const ErrorCode$Notfound = () => new Notfound();
export const ErrorCode$isNotfound = (value) => value instanceof Notfound;

export class Notice extends $CustomType {}
export const ErrorCode$Notice = () => new Notice();
export const ErrorCode$isNotice = (value) => value instanceof Notice;

export class GenericOk extends $CustomType {}
export const ErrorCode$GenericOk = () => new GenericOk();
export const ErrorCode$isGenericOk = (value) => value instanceof GenericOk;

export class Perm extends $CustomType {}
export const ErrorCode$Perm = () => new Perm();
export const ErrorCode$isPerm = (value) => value instanceof Perm;

export class Protocol extends $CustomType {}
export const ErrorCode$Protocol = () => new Protocol();
export const ErrorCode$isProtocol = (value) => value instanceof Protocol;

export class Range extends $CustomType {}
export const ErrorCode$Range = () => new Range();
export const ErrorCode$isRange = (value) => value instanceof Range;

export class Readonly extends $CustomType {}
export const ErrorCode$Readonly = () => new Readonly();
export const ErrorCode$isReadonly = (value) => value instanceof Readonly;

export class Row extends $CustomType {}
export const ErrorCode$Row = () => new Row();
export const ErrorCode$isRow = (value) => value instanceof Row;

export class Schema extends $CustomType {}
export const ErrorCode$Schema = () => new Schema();
export const ErrorCode$isSchema = (value) => value instanceof Schema;

export class Toobig extends $CustomType {}
export const ErrorCode$Toobig = () => new Toobig();
export const ErrorCode$isToobig = (value) => value instanceof Toobig;

export class Warning extends $CustomType {}
export const ErrorCode$Warning = () => new Warning();
export const ErrorCode$isWarning = (value) => value instanceof Warning;

export class AbortRollback extends $CustomType {}
export const ErrorCode$AbortRollback = () => new AbortRollback();
export const ErrorCode$isAbortRollback = (value) =>
  value instanceof AbortRollback;

export class AuthUser extends $CustomType {}
export const ErrorCode$AuthUser = () => new AuthUser();
export const ErrorCode$isAuthUser = (value) => value instanceof AuthUser;

export class BusyRecovery extends $CustomType {}
export const ErrorCode$BusyRecovery = () => new BusyRecovery();
export const ErrorCode$isBusyRecovery = (value) =>
  value instanceof BusyRecovery;

export class BusySnapshot extends $CustomType {}
export const ErrorCode$BusySnapshot = () => new BusySnapshot();
export const ErrorCode$isBusySnapshot = (value) =>
  value instanceof BusySnapshot;

export class BusyTimeout extends $CustomType {}
export const ErrorCode$BusyTimeout = () => new BusyTimeout();
export const ErrorCode$isBusyTimeout = (value) => value instanceof BusyTimeout;

export class CantopenConvpath extends $CustomType {}
export const ErrorCode$CantopenConvpath = () => new CantopenConvpath();
export const ErrorCode$isCantopenConvpath = (value) =>
  value instanceof CantopenConvpath;

export class CantopenDirtywal extends $CustomType {}
export const ErrorCode$CantopenDirtywal = () => new CantopenDirtywal();
export const ErrorCode$isCantopenDirtywal = (value) =>
  value instanceof CantopenDirtywal;

export class CantopenFullpath extends $CustomType {}
export const ErrorCode$CantopenFullpath = () => new CantopenFullpath();
export const ErrorCode$isCantopenFullpath = (value) =>
  value instanceof CantopenFullpath;

export class CantopenIsdir extends $CustomType {}
export const ErrorCode$CantopenIsdir = () => new CantopenIsdir();
export const ErrorCode$isCantopenIsdir = (value) =>
  value instanceof CantopenIsdir;

export class CantopenNotempdir extends $CustomType {}
export const ErrorCode$CantopenNotempdir = () => new CantopenNotempdir();
export const ErrorCode$isCantopenNotempdir = (value) =>
  value instanceof CantopenNotempdir;

export class CantopenSymlink extends $CustomType {}
export const ErrorCode$CantopenSymlink = () => new CantopenSymlink();
export const ErrorCode$isCantopenSymlink = (value) =>
  value instanceof CantopenSymlink;

export class ConstraintCheck extends $CustomType {}
export const ErrorCode$ConstraintCheck = () => new ConstraintCheck();
export const ErrorCode$isConstraintCheck = (value) =>
  value instanceof ConstraintCheck;

export class ConstraintCommithook extends $CustomType {}
export const ErrorCode$ConstraintCommithook = () => new ConstraintCommithook();
export const ErrorCode$isConstraintCommithook = (value) =>
  value instanceof ConstraintCommithook;

export class ConstraintDatatype extends $CustomType {}
export const ErrorCode$ConstraintDatatype = () => new ConstraintDatatype();
export const ErrorCode$isConstraintDatatype = (value) =>
  value instanceof ConstraintDatatype;

export class ConstraintForeignkey extends $CustomType {}
export const ErrorCode$ConstraintForeignkey = () => new ConstraintForeignkey();
export const ErrorCode$isConstraintForeignkey = (value) =>
  value instanceof ConstraintForeignkey;

export class ConstraintFunction extends $CustomType {}
export const ErrorCode$ConstraintFunction = () => new ConstraintFunction();
export const ErrorCode$isConstraintFunction = (value) =>
  value instanceof ConstraintFunction;

export class ConstraintNotnull extends $CustomType {}
export const ErrorCode$ConstraintNotnull = () => new ConstraintNotnull();
export const ErrorCode$isConstraintNotnull = (value) =>
  value instanceof ConstraintNotnull;

export class ConstraintPinned extends $CustomType {}
export const ErrorCode$ConstraintPinned = () => new ConstraintPinned();
export const ErrorCode$isConstraintPinned = (value) =>
  value instanceof ConstraintPinned;

export class ConstraintPrimarykey extends $CustomType {}
export const ErrorCode$ConstraintPrimarykey = () => new ConstraintPrimarykey();
export const ErrorCode$isConstraintPrimarykey = (value) =>
  value instanceof ConstraintPrimarykey;

export class ConstraintRowid extends $CustomType {}
export const ErrorCode$ConstraintRowid = () => new ConstraintRowid();
export const ErrorCode$isConstraintRowid = (value) =>
  value instanceof ConstraintRowid;

export class ConstraintTrigger extends $CustomType {}
export const ErrorCode$ConstraintTrigger = () => new ConstraintTrigger();
export const ErrorCode$isConstraintTrigger = (value) =>
  value instanceof ConstraintTrigger;

export class ConstraintUnique extends $CustomType {}
export const ErrorCode$ConstraintUnique = () => new ConstraintUnique();
export const ErrorCode$isConstraintUnique = (value) =>
  value instanceof ConstraintUnique;

export class ConstraintVtab extends $CustomType {}
export const ErrorCode$ConstraintVtab = () => new ConstraintVtab();
export const ErrorCode$isConstraintVtab = (value) =>
  value instanceof ConstraintVtab;

export class CorruptIndex extends $CustomType {}
export const ErrorCode$CorruptIndex = () => new CorruptIndex();
export const ErrorCode$isCorruptIndex = (value) =>
  value instanceof CorruptIndex;

export class CorruptSequence extends $CustomType {}
export const ErrorCode$CorruptSequence = () => new CorruptSequence();
export const ErrorCode$isCorruptSequence = (value) =>
  value instanceof CorruptSequence;

export class CorruptVtab extends $CustomType {}
export const ErrorCode$CorruptVtab = () => new CorruptVtab();
export const ErrorCode$isCorruptVtab = (value) => value instanceof CorruptVtab;

export class ErrorMissingCollseq extends $CustomType {}
export const ErrorCode$ErrorMissingCollseq = () => new ErrorMissingCollseq();
export const ErrorCode$isErrorMissingCollseq = (value) =>
  value instanceof ErrorMissingCollseq;

export class ErrorRetry extends $CustomType {}
export const ErrorCode$ErrorRetry = () => new ErrorRetry();
export const ErrorCode$isErrorRetry = (value) => value instanceof ErrorRetry;

export class ErrorSnapshot extends $CustomType {}
export const ErrorCode$ErrorSnapshot = () => new ErrorSnapshot();
export const ErrorCode$isErrorSnapshot = (value) =>
  value instanceof ErrorSnapshot;

export class IoerrAccess extends $CustomType {}
export const ErrorCode$IoerrAccess = () => new IoerrAccess();
export const ErrorCode$isIoerrAccess = (value) => value instanceof IoerrAccess;

export class IoerrAuth extends $CustomType {}
export const ErrorCode$IoerrAuth = () => new IoerrAuth();
export const ErrorCode$isIoerrAuth = (value) => value instanceof IoerrAuth;

export class IoerrBeginAtomic extends $CustomType {}
export const ErrorCode$IoerrBeginAtomic = () => new IoerrBeginAtomic();
export const ErrorCode$isIoerrBeginAtomic = (value) =>
  value instanceof IoerrBeginAtomic;

export class IoerrBlocked extends $CustomType {}
export const ErrorCode$IoerrBlocked = () => new IoerrBlocked();
export const ErrorCode$isIoerrBlocked = (value) =>
  value instanceof IoerrBlocked;

export class IoerrCheckreservedlock extends $CustomType {}
export const ErrorCode$IoerrCheckreservedlock = () =>
  new IoerrCheckreservedlock();
export const ErrorCode$isIoerrCheckreservedlock = (value) =>
  value instanceof IoerrCheckreservedlock;

export class IoerrClose extends $CustomType {}
export const ErrorCode$IoerrClose = () => new IoerrClose();
export const ErrorCode$isIoerrClose = (value) => value instanceof IoerrClose;

export class IoerrCommitAtomic extends $CustomType {}
export const ErrorCode$IoerrCommitAtomic = () => new IoerrCommitAtomic();
export const ErrorCode$isIoerrCommitAtomic = (value) =>
  value instanceof IoerrCommitAtomic;

export class IoerrConvpath extends $CustomType {}
export const ErrorCode$IoerrConvpath = () => new IoerrConvpath();
export const ErrorCode$isIoerrConvpath = (value) =>
  value instanceof IoerrConvpath;

export class IoerrCorruptfs extends $CustomType {}
export const ErrorCode$IoerrCorruptfs = () => new IoerrCorruptfs();
export const ErrorCode$isIoerrCorruptfs = (value) =>
  value instanceof IoerrCorruptfs;

export class IoerrData extends $CustomType {}
export const ErrorCode$IoerrData = () => new IoerrData();
export const ErrorCode$isIoerrData = (value) => value instanceof IoerrData;

export class IoerrDelete extends $CustomType {}
export const ErrorCode$IoerrDelete = () => new IoerrDelete();
export const ErrorCode$isIoerrDelete = (value) => value instanceof IoerrDelete;

export class IoerrDeleteNoent extends $CustomType {}
export const ErrorCode$IoerrDeleteNoent = () => new IoerrDeleteNoent();
export const ErrorCode$isIoerrDeleteNoent = (value) =>
  value instanceof IoerrDeleteNoent;

export class IoerrDirClose extends $CustomType {}
export const ErrorCode$IoerrDirClose = () => new IoerrDirClose();
export const ErrorCode$isIoerrDirClose = (value) =>
  value instanceof IoerrDirClose;

export class IoerrDirFsync extends $CustomType {}
export const ErrorCode$IoerrDirFsync = () => new IoerrDirFsync();
export const ErrorCode$isIoerrDirFsync = (value) =>
  value instanceof IoerrDirFsync;

export class IoerrFstat extends $CustomType {}
export const ErrorCode$IoerrFstat = () => new IoerrFstat();
export const ErrorCode$isIoerrFstat = (value) => value instanceof IoerrFstat;

export class IoerrFsync extends $CustomType {}
export const ErrorCode$IoerrFsync = () => new IoerrFsync();
export const ErrorCode$isIoerrFsync = (value) => value instanceof IoerrFsync;

export class IoerrGettemppath extends $CustomType {}
export const ErrorCode$IoerrGettemppath = () => new IoerrGettemppath();
export const ErrorCode$isIoerrGettemppath = (value) =>
  value instanceof IoerrGettemppath;

export class IoerrLock extends $CustomType {}
export const ErrorCode$IoerrLock = () => new IoerrLock();
export const ErrorCode$isIoerrLock = (value) => value instanceof IoerrLock;

export class IoerrMmap extends $CustomType {}
export const ErrorCode$IoerrMmap = () => new IoerrMmap();
export const ErrorCode$isIoerrMmap = (value) => value instanceof IoerrMmap;

export class IoerrNomem extends $CustomType {}
export const ErrorCode$IoerrNomem = () => new IoerrNomem();
export const ErrorCode$isIoerrNomem = (value) => value instanceof IoerrNomem;

export class IoerrRdlock extends $CustomType {}
export const ErrorCode$IoerrRdlock = () => new IoerrRdlock();
export const ErrorCode$isIoerrRdlock = (value) => value instanceof IoerrRdlock;

/**
 * Convert an `Error` to an error code int.
 *
 * See the SQLite documentation for the full list of error codes.
 * <https://sqlite.org/rescode.html>
 */
export function error_code_to_int(error) {
  if (error instanceof Abort) {
    return 4;
  } else if (error instanceof Auth) {
    return 23;
  } else if (error instanceof Busy) {
    return 5;
  } else if (error instanceof Cantopen) {
    return 14;
  } else if (error instanceof Constraint) {
    return 19;
  } else if (error instanceof Corrupt) {
    return 11;
  } else if (error instanceof Done) {
    return 101;
  } else if (error instanceof Empty) {
    return 16;
  } else if (error instanceof GenericError) {
    return 1;
  } else if (error instanceof Format) {
    return 24;
  } else if (error instanceof Full) {
    return 13;
  } else if (error instanceof Internal) {
    return 2;
  } else if (error instanceof Interrupt) {
    return 9;
  } else if (error instanceof Ioerr) {
    return 10;
  } else if (error instanceof Locked) {
    return 6;
  } else if (error instanceof Mismatch) {
    return 20;
  } else if (error instanceof Misuse) {
    return 21;
  } else if (error instanceof Nolfs) {
    return 22;
  } else if (error instanceof Nomem) {
    return 7;
  } else if (error instanceof Notadb) {
    return 26;
  } else if (error instanceof Notfound) {
    return 12;
  } else if (error instanceof Notice) {
    return 27;
  } else if (error instanceof GenericOk) {
    return 0;
  } else if (error instanceof Perm) {
    return 3;
  } else if (error instanceof Protocol) {
    return 15;
  } else if (error instanceof Range) {
    return 25;
  } else if (error instanceof Readonly) {
    return 8;
  } else if (error instanceof Row) {
    return 100;
  } else if (error instanceof Schema) {
    return 17;
  } else if (error instanceof Toobig) {
    return 18;
  } else if (error instanceof Warning) {
    return 28;
  } else if (error instanceof AbortRollback) {
    return 516;
  } else if (error instanceof AuthUser) {
    return 279;
  } else if (error instanceof BusyRecovery) {
    return 261;
  } else if (error instanceof BusySnapshot) {
    return 517;
  } else if (error instanceof BusyTimeout) {
    return 773;
  } else if (error instanceof CantopenConvpath) {
    return 1038;
  } else if (error instanceof CantopenDirtywal) {
    return 1294;
  } else if (error instanceof CantopenFullpath) {
    return 782;
  } else if (error instanceof CantopenIsdir) {
    return 526;
  } else if (error instanceof CantopenNotempdir) {
    return 270;
  } else if (error instanceof CantopenSymlink) {
    return 1550;
  } else if (error instanceof ConstraintCheck) {
    return 275;
  } else if (error instanceof ConstraintCommithook) {
    return 531;
  } else if (error instanceof ConstraintDatatype) {
    return 3091;
  } else if (error instanceof ConstraintForeignkey) {
    return 787;
  } else if (error instanceof ConstraintFunction) {
    return 1043;
  } else if (error instanceof ConstraintNotnull) {
    return 1299;
  } else if (error instanceof ConstraintPinned) {
    return 2835;
  } else if (error instanceof ConstraintPrimarykey) {
    return 1555;
  } else if (error instanceof ConstraintRowid) {
    return 2579;
  } else if (error instanceof ConstraintTrigger) {
    return 1811;
  } else if (error instanceof ConstraintUnique) {
    return 2067;
  } else if (error instanceof ConstraintVtab) {
    return 2323;
  } else if (error instanceof CorruptIndex) {
    return 779;
  } else if (error instanceof CorruptSequence) {
    return 523;
  } else if (error instanceof CorruptVtab) {
    return 267;
  } else if (error instanceof ErrorMissingCollseq) {
    return 257;
  } else if (error instanceof ErrorRetry) {
    return 513;
  } else if (error instanceof ErrorSnapshot) {
    return 769;
  } else if (error instanceof IoerrAccess) {
    return 3338;
  } else if (error instanceof IoerrAuth) {
    return 7178;
  } else if (error instanceof IoerrBeginAtomic) {
    return 7434;
  } else if (error instanceof IoerrBlocked) {
    return 2826;
  } else if (error instanceof IoerrCheckreservedlock) {
    return 3594;
  } else if (error instanceof IoerrClose) {
    return 4106;
  } else if (error instanceof IoerrCommitAtomic) {
    return 7690;
  } else if (error instanceof IoerrConvpath) {
    return 6666;
  } else if (error instanceof IoerrCorruptfs) {
    return 8458;
  } else if (error instanceof IoerrData) {
    return 8202;
  } else if (error instanceof IoerrDelete) {
    return 2570;
  } else if (error instanceof IoerrDeleteNoent) {
    return 5898;
  } else if (error instanceof IoerrDirClose) {
    return 4362;
  } else if (error instanceof IoerrDirFsync) {
    return 1290;
  } else if (error instanceof IoerrFstat) {
    return 1802;
  } else if (error instanceof IoerrFsync) {
    return 1034;
  } else if (error instanceof IoerrGettemppath) {
    return 6410;
  } else if (error instanceof IoerrLock) {
    return 3850;
  } else if (error instanceof IoerrMmap) {
    return 6154;
  } else if (error instanceof IoerrNomem) {
    return 3082;
  } else {
    return 2314;
  }
}

/**
 * Convert an error code int to an `Error`.
 *
 * If the code is not a known error code, `GenericError` is returned.
 */
export function error_code_from_int(code) {
  if (code === 4) {
    return new Abort();
  } else if (code === 23) {
    return new Auth();
  } else if (code === 5) {
    return new Busy();
  } else if (code === 14) {
    return new Cantopen();
  } else if (code === 19) {
    return new Constraint();
  } else if (code === 11) {
    return new Corrupt();
  } else if (code === 101) {
    return new Done();
  } else if (code === 16) {
    return new Empty();
  } else if (code === 1) {
    return new GenericError();
  } else if (code === 24) {
    return new Format();
  } else if (code === 13) {
    return new Full();
  } else if (code === 2) {
    return new Internal();
  } else if (code === 9) {
    return new Interrupt();
  } else if (code === 10) {
    return new Ioerr();
  } else if (code === 6) {
    return new Locked();
  } else if (code === 20) {
    return new Mismatch();
  } else if (code === 21) {
    return new Misuse();
  } else if (code === 22) {
    return new Nolfs();
  } else if (code === 7) {
    return new Nomem();
  } else if (code === 26) {
    return new Notadb();
  } else if (code === 12) {
    return new Notfound();
  } else if (code === 27) {
    return new Notice();
  } else if (code === 0) {
    return new GenericOk();
  } else if (code === 3) {
    return new Perm();
  } else if (code === 15) {
    return new Protocol();
  } else if (code === 25) {
    return new Range();
  } else if (code === 8) {
    return new Readonly();
  } else if (code === 100) {
    return new Row();
  } else if (code === 17) {
    return new Schema();
  } else if (code === 18) {
    return new Toobig();
  } else if (code === 28) {
    return new Warning();
  } else if (code === 516) {
    return new AbortRollback();
  } else if (code === 279) {
    return new AuthUser();
  } else if (code === 261) {
    return new BusyRecovery();
  } else if (code === 517) {
    return new BusySnapshot();
  } else if (code === 773) {
    return new BusyTimeout();
  } else if (code === 1038) {
    return new CantopenConvpath();
  } else if (code === 1294) {
    return new CantopenDirtywal();
  } else if (code === 782) {
    return new CantopenFullpath();
  } else if (code === 526) {
    return new CantopenIsdir();
  } else if (code === 270) {
    return new CantopenNotempdir();
  } else if (code === 1550) {
    return new CantopenSymlink();
  } else if (code === 275) {
    return new ConstraintCheck();
  } else if (code === 531) {
    return new ConstraintCommithook();
  } else if (code === 3091) {
    return new ConstraintDatatype();
  } else if (code === 787) {
    return new ConstraintForeignkey();
  } else if (code === 1043) {
    return new ConstraintFunction();
  } else if (code === 1299) {
    return new ConstraintNotnull();
  } else if (code === 2835) {
    return new ConstraintPinned();
  } else if (code === 1555) {
    return new ConstraintPrimarykey();
  } else if (code === 2579) {
    return new ConstraintRowid();
  } else if (code === 1811) {
    return new ConstraintTrigger();
  } else if (code === 2067) {
    return new ConstraintUnique();
  } else if (code === 2323) {
    return new ConstraintVtab();
  } else if (code === 779) {
    return new CorruptIndex();
  } else if (code === 523) {
    return new CorruptSequence();
  } else if (code === 267) {
    return new CorruptVtab();
  } else if (code === 257) {
    return new ErrorMissingCollseq();
  } else if (code === 513) {
    return new ErrorRetry();
  } else if (code === 769) {
    return new ErrorSnapshot();
  } else if (code === 3338) {
    return new IoerrAccess();
  } else if (code === 7178) {
    return new IoerrAuth();
  } else if (code === 7434) {
    return new IoerrBeginAtomic();
  } else if (code === 2826) {
    return new IoerrBlocked();
  } else if (code === 3594) {
    return new IoerrCheckreservedlock();
  } else if (code === 4106) {
    return new IoerrClose();
  } else if (code === 7690) {
    return new IoerrCommitAtomic();
  } else if (code === 6666) {
    return new IoerrConvpath();
  } else if (code === 8458) {
    return new IoerrCorruptfs();
  } else if (code === 8202) {
    return new IoerrData();
  } else if (code === 2570) {
    return new IoerrDelete();
  } else if (code === 5898) {
    return new IoerrDeleteNoent();
  } else if (code === 4362) {
    return new IoerrDirClose();
  } else if (code === 1290) {
    return new IoerrDirFsync();
  } else if (code === 1802) {
    return new IoerrFstat();
  } else if (code === 1034) {
    return new IoerrFsync();
  } else if (code === 6410) {
    return new IoerrGettemppath();
  } else if (code === 3850) {
    return new IoerrLock();
  } else if (code === 6154) {
    return new IoerrMmap();
  } else if (code === 3082) {
    return new IoerrNomem();
  } else if (code === 2314) {
    return new IoerrRdlock();
  } else {
    return new GenericError();
  }
}

/**
 * Open a connection to a SQLite database.
 *
 * URI filenames are supported by SQLite, making it possible to open read-only
 * databases, in memory databases, and more. Further information about this can
 * be found in the SQLite documentation: <https://sqlite.org/uri.html>.
 *
 * # Examples
 *
 * ## Open "data.db" in the current working directory
 *
 * ```gleam
 * let assert Ok(conn) = open("file:data.sqlite3")
 * ```
 * 
 * ## Opens "data.db" in read only mode with a private cache
 * 
 * ```gleam
 * let assert Ok(conn) = open("file:data.db?mode=ro&cache=private")
 * ```
 * 
 * Opens a shared memory database named memdb1 with a shared cache. 
 * 
 * ```gleam
 * let assert Ok(conn) = open("file:memdb1?mode=memory&cache=shared")
 * ```
 */
export function open(path) {
  return open_(path);
}

/**
 * Close a connection to a SQLite database.
 *
 * Ideally applications should finallise all prepared statements and other open
 * resources before closing a connection. See the SQLite documentation for more
 * information: <https://www.sqlite.org/c3ref/close.html>.
 */
export function close(connection) {
  return close_(connection);
}

/**
 * Open a connection to a SQLite database and execute a function with it,.try
 * close the connection.
 *
 * This function works well with a `use` expression to automatically close the
 * connection at the end of a block.
 *
 * # Crashes
 *
 * This function crashes if the connection cannot be opened or closed.
 *
 * # Examples
 *
 * ```gleam
 * use conn <- with_connection("file:mydb?mode=memory")
 * // Use the connection here...
 * ```
 */
export function with_connection(path, f) {
  let $ = open(path);
  let connection;
  if ($ instanceof Ok) {
    connection = $[0];
  } else {
    throw makeError(
      "let_assert",
      FILEPATH,
      "sqlight",
      368,
      "with_connection",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $,
        start: 8325,
        end: 8363,
        pattern_start: 8336,
        pattern_end: 8350
      }
    )
  }
  let value = f(connection);
  let $1 = close(connection);
  if (!($1 instanceof Ok)) {
    throw makeError(
      "let_assert",
      FILEPATH,
      "sqlight",
      370,
      "with_connection",
      "Pattern match failed, no pattern matched the value.",
      {
        value: $1,
        start: 8394,
        end: 8430,
        pattern_start: 8405,
        pattern_end: 8410
      }
    )
  }
  return value;
}

export function exec(sql, connection) {
  return exec_(sql, connection);
}

/**
 * Convert a Gleam `Int` to an SQLite int, to be used an argument to a
 * query.
 */
export function int(value) {
  return coerce_value(value);
}

/**
 * Convert a Gleam `Float` to an SQLite float, to be used an argument to a
 * query.
 */
export function float(value) {
  return coerce_value(value);
}

/**
 * Convert a Gleam `String` to an SQLite text, to be used an argument to a
 * query.
 */
export function text(value) {
  return coerce_value(value);
}

/**
 * Convert a Gleam `Bool` to an SQLite int, to be used an argument to a
 * query.
 *
 * SQLite does not have a native boolean type. Instead, it uses ints, where 0
 * is False and 1 is True. Because of this the Gleam stdlib decoder for bools
 * will not work, instead the `decode_bool` function should be used as it
 * supports both ints and bools.
 */
export function bool(value) {
  return int(
    (() => {
      if (value) {
        return 1;
      } else {
        return 0;
      }
    })(),
  );
}

/**
 * Convert a Gleam `Option` to an SQLite nullable value, to be used an argument
 * to a query.
 */
export function nullable(inner_type, value) {
  if (value instanceof Some) {
    let value$1 = value[0];
    return inner_type(value$1);
  } else {
    return null$();
  }
}

/**
 * Decode an SQLite boolean value.
 *
 * Decodes 0 as `False` and any other integer as `True`.
 */
export function decode_bool() {
  return $decode.then$(
    $decode.int,
    (b) => {
      if (b === 0) {
        return $decode.success(false);
      } else {
        return $decode.success(true);
      }
    },
  );
}

function decode_error(errors) {
  let expected;
  let actual;
  let path;
  if (errors instanceof $Empty) {
    throw makeError(
      "let_assert",
      FILEPATH,
      "sqlight",
      481,
      "decode_error",
      "Pattern match failed, no pattern matched the value.",
      {
        value: errors,
        start: 11296,
        end: 11364,
        pattern_start: 11307,
        pattern_end: 11355
      }
    )
  } else {
    expected = errors.head.expected;
    actual = errors.head.found;
    path = errors.head.path;
  }
  let path$1 = $string.join(path, ".");
  let message = (((("Decoder failed, expected " + expected) + ", got ") + actual) + " in ") + path$1;
  return new SqlightError(new GenericError(), message, -1);
}

export function query(sql, connection, arguments$, decoder) {
  return $result.try$(
    run_query(sql, connection, arguments$),
    (rows) => {
      return $result.try$(
        (() => {
          let _pipe = $list.try_map(
            rows,
            (row) => { return $decode.run(row, decoder); },
          );
          return $result.map_error(_pipe, decode_error);
        })(),
        (rows) => { return new Ok(rows); },
      );
    },
  );
}
