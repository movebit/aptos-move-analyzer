# Changelogs:

## 2025/4/30 v1.0.5
- add warning between `aptos-moveanalyzer::format enable` and `vscode::format on save`.[(#issue33)](https://github.com/movebit/aptos-move-analyzer/issues/35)
- try avoiding to truncating source code.[(#issue33)](https://github.com/movebit/aptos-move-analyzer/issues/32)
- optimize speed on InlayHInts.  [(#issue32)](https://github.com/movebit/aptos-move-analyzer/issues/32)
- optimize speed on foramt. [(#issue31)](https://github.com/movebit/aptos-move-analyzer/issues/31)



## 2024/7/8 v1.0.0
- supported `receiver style call`
- `find reference` supported generic types in function header
- `find reference` supported pack and unpack in the function body

## 2024/9/4 v1.0.1
- auto download lsp-server from lsp-client
- add plugin option[proxy.addr] for downloading lsp-server
- add aptos-move tests projects
- support goto on return type of fun
- support goto on builtin fun
- upgrade dep about aptos-core to release 4.1.0
- support goto on test code block
- optimize goto on generic type in struct def

## 2024/9/20 v1.0.2
- support goto on enum's field type
- support goto on match exp

## 2024/10/08 v1.0.3
- fix issue#11: fixed panic bug when called StructEnv::get_variants()
- support find references on const
- support find references on ENUM
- fix issue#13: build failed when conflicting modules occur

## 2024/10/14 v1.0.4
- fix issue#12: odd behaviors with diag report
- add clear_ui_diag()
- optimize code

## 2025/1/24 v1.0.5
- fix bug on get_global_env_by_move_package_v2() which cause some error "unbound module ..."
- fix bug on process_use_decl() about addr_name's format
- update the move-model dependency of aptos-core
- update formatting code feature
- optimize code
- add test cases and improve UT

## 2025/2/25 v1.0.5
- fix bug on The Field 'Server Path' of extension configure not work.[(#issue24)](https://github.com/movebit/aptos-move-analyzer/issues/24)
- fix bug on go-to-definition for `use`. [(#issue21)](https://github.com/movebit/aptos-move-analyzer/issues/21)
- fix bug on auto-complete for `std` or `aptos-framework`. [(#issue25)](https://github.com/movebit/aptos-move-analyzer/issues/25)
- optimize speed on save file when `Ctrl+S`. [(#issue23)](https://github.com/movebit/aptos-move-analyzer/issues/23)
- optimize speed on auto-complete. [(#issue26)](https://github.com/movebit/aptos-move-analyzer/issues/26)
- optimize code

