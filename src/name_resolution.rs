use crate::ext::LocExt;
use crate::utils::{fpath_str_is_equal, get_modules_by_fpath_in_all_modules};
use move_model::ast::{ModuleName, UseDecl};
use move_model::model::{GlobalEnv, ModuleEnv};
use std::path::{Path, PathBuf};

pub enum Reference {
    UseModule {
        use_decl: UseDecl,
        module_name: ModuleName,
    },
    UseItem {
        use_decl: UseDecl,
        item_loc: move_model::model::Loc,
        item_name: String,
    },
    // Function(FunctionEnv<'a>),
    // Struct(StructEnv<'a>),
}

pub fn find_reference(
    env: &GlobalEnv,
    source_fpath: &Path,
    position: (u32, u32),
) -> Option<Reference> {
    let fpath = PathBuf::from(source_fpath);
    let Some(ref_module) = get_modules_by_fpath_in_all_modules(env, &fpath)
        .into_iter()
        .find(|m| m.get_loc().contains(&env, position))
    else {
        println!("ref is not inside a module");
        return None;
    };

    let maybe_use_decl = ref_module
        .get_use_decls()
        .iter()
        .find(|u| u.loc.contains(&env, position));
    if let Some(use_decl) = maybe_use_decl {
        if use_decl.members.is_empty() {
            // use 0x1::m;
            let module_name = use_decl.module_name.clone();
            return Some(Reference::UseModule {
                use_decl: use_decl.clone(),
                module_name,
            });
        }
        for (item_loc, item_sym, _item_alias) in use_decl.members.clone() {
            if item_loc.contains(&env, position) {
                return Some(Reference::UseItem {
                    use_decl: use_decl.clone(),
                    item_loc,
                    item_name: item_sym.display(env.symbol_pool()).to_string(),
                });
            }
        }
    }

    // let maybe_outer_func = ref_module
    //     .get_functions()
    //     .find(|f| f.get_loc().contains(&env, position));
    // if let Some(outer_func) = maybe_outer_func {
    //     // reference belongs to a function body
    //     let fun_params = outer_func.get_parameters();
    //     for (idx, param) in fun_params.iter().enumerate() {
    //
    //
    //     }
    // }

    // let maybe_struct = ref_module
    //     .get_structs()
    //     .find(|f| f.get_loc().contains(&env, position));
    // if let Some(struct_) = maybe_struct {
    //     return Some(Reference::Struct(struct_));
    // }

    None
}
