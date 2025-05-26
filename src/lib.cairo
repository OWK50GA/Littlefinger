pub mod contracts {
    pub mod core;
    pub mod factory;
    pub mod vault;
}
pub mod interfaces {
    pub mod idisbursement;
    pub mod imember_manager;
    pub mod ivault;
    pub mod iorganization;
    pub mod voting;
    pub mod ifactory;
    pub mod icore;
}

pub mod components {
    pub mod disbursement;
    pub mod member_manager;
    pub mod organization;
    pub mod voting;
}

pub mod structs {
    pub mod base;
    pub mod core;
    pub mod disbursement_structs;
    pub mod member_structs;
    pub mod organization;
    pub mod voting;
    pub mod vault_structs;
}
