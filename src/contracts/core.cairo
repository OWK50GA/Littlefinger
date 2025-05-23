#[starknet::contract]
mod Core {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starknet::{ClassHash, ContractAddress};
    use crate::components::member_manager::MemberManagerComponent;
    use crate::components::organization::OrganizationComponent;
    use crate::structs::organization::{OrganizationConfig, OrganizationInfo, OwnerInit};
    use crate::components::voting::VotingComponent;
    use crate::components::disbursement::DisbursementComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: MemberManagerComponent, storage: member, event: MemberEvent);
    component!(path: OrganizationComponent, storage: organization, event: OrganizationEvent);
    component!(path: VotingComponent, storage: voting, event: VotingEvent);
    component!(path: DisbursementComponent, storage: disbursement, event: DisbursementEvent);

    #[abi(embed_v0)]
    impl MemberImpl = MemberManagerComponent::MemberManager<ContractState>;
    #[abi(embed_v0)]
    impl DisbursementImpl = DisbursementComponent::DisbursementManager<ContractState>;
    #[abi(embed_v0)]
    impl OrganizationImpl = OrganizationComponent::OrganizationManager<ContractState>;
    #[abi(embed_v0)]
    impl VotingImpl = VotingComponent::VotingImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    #[allow(starknet::colliding_storage_paths)]
    struct Storage {
        #[substorage(v0)]
        member: MemberManagerComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        #[substorage(v0)]
        organization: OrganizationComponent::Storage,
        #[substorage(v0)]
        voting: VotingComponent::Storage,
        #[substorage(v0)]
        disbursement: DisbursementComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MemberEvent: MemberManagerComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        #[flat]
        OrganizationEvent: OrganizationComponent::Event,
        #[flat]
        VotingEvent: VotingComponent::Event,
        #[flat]
        DisbursementEvent: DisbursementComponent::Event,
    }

    // #[derive(Drop, Copy, Serde)]
    // pub struct OwnerInit {
    //     pub address: ContractAddress,
    //     pub fnmae: felt252,
    //     pub lastname: felt252,
    // }

    #[constructor]
    fn constructor(ref self: ContractState, organization_config: OrganizationConfig) { // owner
        
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            // This might be upgraded from the factory
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
