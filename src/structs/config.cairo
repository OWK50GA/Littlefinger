use starknet::ContractAddress;

#[derive(Drop, Copy, PartialEq, Serde, Debug, Default)]
pub struct CoreConfig {}

#[derive(Drop, Copy, PartialEq, Default)]
pub enum Visibility {
    #[default]
    Public,
    Private,
}

#[derive(Drop, Copy, Serde, PartialEq, Default)]
pub struct PaymentConfig {
    pub broker: Option<ContractAddress>,
    pub payment_type: PaymentType,
}

// There might be other payment types available for this Config
#[derive(Drop, Copy, Serde, Default, PartialEq)]
pub enum PaymentType {
    #[default]
    Basic,
    Stream,
}

// Only if Stream, retrieve the stream details
#[derive(Drop, Copy, Serde, Default)]
pub struct StreamDetails { // init stream details
}

#[starknet::storage_node]
pub struct CoreConfigNode {}

pub fn get_default_stream_details() -> StreamDetails {
    Default::default()
}

