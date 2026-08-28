import 'package:highlight/highlight_core.dart' as core;
import 'package:highlight/languages/dart.dart' as lang_dart;
import 'package:highlight/languages/javascript.dart' as lang_javascript;
import 'package:highlight/languages/typescript.dart' as lang_typescript;
import 'package:highlight/languages/python.dart' as lang_python;
import 'package:highlight/languages/java.dart' as lang_java;
import 'package:highlight/languages/kotlin.dart' as lang_kotlin;
import 'package:highlight/languages/swift.dart' as lang_swift;
import 'package:highlight/languages/objectivec.dart' as lang_objectivec;
import 'package:highlight/languages/cpp.dart' as lang_cpp;
import 'package:highlight/languages/cs.dart' as lang_cs;
import 'package:highlight/languages/go.dart' as lang_go;
import 'package:highlight/languages/rust.dart' as lang_rust;
import 'package:highlight/languages/ruby.dart' as lang_ruby;
import 'package:highlight/languages/php.dart' as lang_php;
import 'package:highlight/languages/scala.dart' as lang_scala;
import 'package:highlight/languages/perl.dart' as lang_perl;
import 'package:highlight/languages/lua.dart' as lang_lua;
import 'package:highlight/languages/r.dart' as lang_r;
import 'package:highlight/languages/shell.dart' as lang_shell;
import 'package:highlight/languages/bash.dart' as lang_bash;
import 'package:highlight/languages/powershell.dart' as lang_powershell;
import 'package:highlight/languages/sql.dart' as lang_sql;
import 'package:highlight/languages/pgsql.dart' as lang_pgsql;
import 'package:highlight/languages/json.dart' as lang_json;
import 'package:highlight/languages/yaml.dart' as lang_yaml;
import 'package:highlight/languages/xml.dart' as lang_xml;
import 'package:highlight/languages/markdown.dart' as lang_markdown;
import 'package:highlight/languages/css.dart' as lang_css;
import 'package:highlight/languages/scss.dart' as lang_scss;
import 'package:highlight/languages/less.dart' as lang_less;
import 'package:highlight/languages/http.dart' as lang_http;
import 'package:highlight/languages/dockerfile.dart' as lang_dockerfile;
import 'package:highlight/languages/makefile.dart' as lang_makefile;
import 'package:highlight/languages/ini.dart' as lang_ini;
import 'package:highlight/languages/nginx.dart' as lang_nginx;
import 'package:highlight/languages/apache.dart' as lang_apache;
import 'package:highlight/languages/diff.dart' as lang_diff;
import 'package:highlight/languages/graphql.dart' as lang_graphql;
import 'package:highlight/languages/groovy.dart' as lang_groovy;
import 'package:highlight/languages/vim.dart' as lang_vim;
import 'package:highlight/languages/plaintext.dart' as lang_plaintext;
import 'package:highlight/languages/properties.dart' as lang_properties;
import 'package:highlight/languages/protobuf.dart' as lang_protobuf;
import 'package:highlight/languages/haskell.dart' as lang_haskell;
import 'package:highlight/languages/elixir.dart' as lang_elixir;
import 'package:highlight/languages/erlang.dart' as lang_erlang;
import 'package:highlight/languages/clojure.dart' as lang_clojure;
import 'package:highlight/languages/coffeescript.dart' as lang_coffeescript;
import 'package:highlight/languages/matlab.dart' as lang_matlab;
import 'package:highlight/languages/julia.dart' as lang_julia;
import 'package:highlight/languages/fortran.dart' as lang_fortran;
import 'package:highlight/languages/vbnet.dart' as lang_vbnet;
import 'package:highlight/languages/delphi.dart' as lang_delphi;
import 'package:highlight/languages/lisp.dart' as lang_lisp;

/// The languages code blocks are coloured for.
///
/// `package:highlight/highlight.dart` — the entry point everything reaches for
/// first — begins by importing `languages/all.dart` and registering every one
/// of the 189 definitions it ships. Nothing can be tree-shaken away after
/// that, because the map it registers from names them all, so the whole
/// 1.9 MB went into the AOT snapshot whether a reader ever wrote a line of
/// Solidity or not.
///
/// That mattered once it was measured: on the machine where a launch takes
/// seconds, `window.Create()` — engine boot plus loading the snapshot — is
/// where all of the time goes, and taking 2.2 MB out of app.so took about
/// 450 ms off it. Roughly 200 ms per megabyte.
///
/// The list below keeps what a Markdown document plausibly contains. What it
/// drops is the long tail: `isbl` (a Russian document-management DSL) alone
/// was 244 KB, `solidity` 196 KB, `mathematica` 96 KB, `1c` 60 KB — none of
/// which anybody was ever going to put in a code fence here.
///
/// A language that is not on this list still shows its code; it simply shows
/// it uncoloured, which is what happened for every language before any of this
/// existed.
class CodeHighlighting {
  CodeHighlighting._();

  static core.Highlight? _instance;

  /// The shared highlighter, with this list registered on first use.
  static core.Highlight get instance => _instance ??= core.Highlight()
      ..registerLanguage('dart', lang_dart.dart)
      ..registerLanguage('javascript', lang_javascript.javascript)
      ..registerLanguage('typescript', lang_typescript.typescript)
      ..registerLanguage('python', lang_python.python)
      ..registerLanguage('java', lang_java.java)
      ..registerLanguage('kotlin', lang_kotlin.kotlin)
      ..registerLanguage('swift', lang_swift.swift)
      ..registerLanguage('objectivec', lang_objectivec.objectivec)
      ..registerLanguage('cpp', lang_cpp.cpp)
      ..registerLanguage('cs', lang_cs.cs)
      ..registerLanguage('go', lang_go.go)
      ..registerLanguage('rust', lang_rust.rust)
      ..registerLanguage('ruby', lang_ruby.ruby)
      ..registerLanguage('php', lang_php.php)
      ..registerLanguage('scala', lang_scala.scala)
      ..registerLanguage('perl', lang_perl.perl)
      ..registerLanguage('lua', lang_lua.lua)
      ..registerLanguage('r', lang_r.r)
      ..registerLanguage('shell', lang_shell.shell)
      ..registerLanguage('bash', lang_bash.bash)
      ..registerLanguage('powershell', lang_powershell.powershell)
      ..registerLanguage('sql', lang_sql.sql)
      ..registerLanguage('pgsql', lang_pgsql.pgsql)
      ..registerLanguage('json', lang_json.json)
      ..registerLanguage('yaml', lang_yaml.yaml)
      ..registerLanguage('xml', lang_xml.xml)
      ..registerLanguage('markdown', lang_markdown.markdown)
      ..registerLanguage('css', lang_css.css)
      ..registerLanguage('scss', lang_scss.scss)
      ..registerLanguage('less', lang_less.less)
      ..registerLanguage('http', lang_http.http)
      ..registerLanguage('dockerfile', lang_dockerfile.dockerfile)
      ..registerLanguage('makefile', lang_makefile.makefile)
      ..registerLanguage('ini', lang_ini.ini)
      ..registerLanguage('nginx', lang_nginx.nginx)
      ..registerLanguage('apache', lang_apache.apache)
      ..registerLanguage('diff', lang_diff.diff)
      ..registerLanguage('graphql', lang_graphql.graphql)
      ..registerLanguage('groovy', lang_groovy.groovy)
      ..registerLanguage('vim', lang_vim.vim)
      ..registerLanguage('plaintext', lang_plaintext.plaintext)
      ..registerLanguage('properties', lang_properties.properties)
      ..registerLanguage('protobuf', lang_protobuf.protobuf)
      ..registerLanguage('haskell', lang_haskell.haskell)
      ..registerLanguage('elixir', lang_elixir.elixir)
      ..registerLanguage('erlang', lang_erlang.erlang)
      ..registerLanguage('clojure', lang_clojure.clojure)
      ..registerLanguage('coffeescript', lang_coffeescript.coffeescript)
      ..registerLanguage('matlab', lang_matlab.matlab)
      ..registerLanguage('julia', lang_julia.julia)
      ..registerLanguage('fortran', lang_fortran.fortran)
      ..registerLanguage('vbnet', lang_vbnet.vbnet)
      ..registerLanguage('delphi', lang_delphi.delphi)
      ..registerLanguage('lisp', lang_lisp.lisp);

  /// The names registered above, for tests and for anything that needs to know
  /// whether a fence will be coloured.
  static const languages = <String>[
    'dart',
    'javascript',
    'typescript',
    'python',
    'java',
    'kotlin',
    'swift',
    'objectivec',
    'cpp',
    'cs',
    'go',
    'rust',
    'ruby',
    'php',
    'scala',
    'perl',
    'lua',
    'r',
    'shell',
    'bash',
    'powershell',
    'sql',
    'pgsql',
    'json',
    'yaml',
    'xml',
    'markdown',
    'css',
    'scss',
    'less',
    'http',
    'dockerfile',
    'makefile',
    'ini',
    'nginx',
    'apache',
    'diff',
    'graphql',
    'groovy',
    'vim',
    'plaintext',
    'properties',
    'protobuf',
    'haskell',
    'elixir',
    'erlang',
    'clojure',
    'coffeescript',
    'matlab',
    'julia',
    'fortran',
    'vbnet',
    'delphi',
    'lisp',
  ];
}
