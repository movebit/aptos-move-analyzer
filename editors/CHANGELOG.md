# Changelogs:

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
