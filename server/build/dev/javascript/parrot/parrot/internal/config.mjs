import * as $filepath from "../../../filepath/filepath.mjs";
import * as $simplifile from "../../../simplifile/simplifile.mjs";
import { CustomType as $CustomType } from "../../gleam.mjs";
import * as $project from "../../parrot/internal/project.mjs";

export class Config extends $CustomType {
  constructor(json_file_path, gleam_module_out_path) {
    super();
    this.json_file_path = json_file_path;
    this.gleam_module_out_path = gleam_module_out_path;
  }
}
export const Config$Config = (json_file_path, gleam_module_out_path) =>
  new Config(json_file_path, gleam_module_out_path);
export const Config$isConfig = (value) => value instanceof Config;
export const Config$Config$json_file_path = (value) => value.json_file_path;
export const Config$Config$0 = (value) => value.json_file_path;
export const Config$Config$gleam_module_out_path = (value) =>
  value.gleam_module_out_path;
export const Config$Config$1 = (value) => value.gleam_module_out_path;

export function get_json_file(config) {
  let path = $filepath.join($project.root(), config.json_file_path);
  return $simplifile.read(path);
}

export function get_module_directory(config) {
  let _pipe = $filepath.join($project.src(), config.gleam_module_out_path);
  return $filepath.directory_name(_pipe);
}

export function get_module_path(config) {
  return $filepath.join($project.src(), config.gleam_module_out_path);
}
