use std::path::{Component, PathBuf};

pub(crate) fn has_path_component_with_name(path: &PathBuf, name: &str) -> bool {
    for component in path.components() {
        if let Component::Normal(comp_name) = component {
            if comp_name == name {
                return true;
            }
        }
    }
    false
}
