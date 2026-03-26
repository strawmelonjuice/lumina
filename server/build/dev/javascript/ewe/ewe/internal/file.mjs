import * as $bytes_tree from "../../../gleam_stdlib/gleam/bytes_tree.mjs";
import * as $dynamic from "../../../gleam_stdlib/gleam/dynamic.mjs";
import * as $result from "../../../gleam_stdlib/gleam/result.mjs";
import * as $glisten from "../../../glisten/glisten.mjs";
import * as $socket from "../../../glisten/glisten/socket.mjs";
import * as $transport from "../../../glisten/glisten/transport.mjs";
import { CustomType as $CustomType } from "../../gleam.mjs";

export class Enoent extends $CustomType {}
export const FileError$Enoent = () => new Enoent();
export const FileError$isEnoent = (value) => value instanceof Enoent;

export class Eacces extends $CustomType {}
export const FileError$Eacces = () => new Eacces();
export const FileError$isEacces = (value) => value instanceof Eacces;

export class Eisdir extends $CustomType {}
export const FileError$Eisdir = () => new Eisdir();
export const FileError$isEisdir = (value) => value instanceof Eisdir;

export class Eunknown extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const FileError$Eunknown = ($0) => new Eunknown($0);
export const FileError$isEunknown = (value) => value instanceof Eunknown;
export const FileError$Eunknown$0 = (value) => value[0];

export class File extends $CustomType {
  constructor(descriptor, size) {
    super();
    this.descriptor = descriptor;
    this.size = size;
  }
}
export const File$File = (descriptor, size) => new File(descriptor, size);
export const File$isFile = (value) => value instanceof File;
export const File$File$descriptor = (value) => value.descriptor;
export const File$File$0 = (value) => value.descriptor;
export const File$File$size = (value) => value.size;
export const File$File$1 = (value) => value.size;

export class FileIssue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const SendError$FileIssue = ($0) => new FileIssue($0);
export const SendError$isFileIssue = (value) => value instanceof FileIssue;
export const SendError$FileIssue$0 = (value) => value[0];

export class SocketIssue extends $CustomType {
  constructor($0) {
    super();
    this[0] = $0;
  }
}
export const SendError$SocketIssue = ($0) => new SocketIssue($0);
export const SendError$isSocketIssue = (value) => value instanceof SocketIssue;
export const SendError$SocketIssue$0 = (value) => value[0];
