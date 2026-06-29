/// Interface representing `Counter`.
/// This interface allows modification and retrieval of the contract's storage count.
#[starknet::interface]
pub trait ICounter<T> {
    fn increase_count(ref self: T, amount: u32);
    fn decrease_count(ref self: T, amount: u32);
    fn reset_count(ref self: T);
    fn get_count(self: @T) -> u32;
    fn get_owner(self: @T) -> starknet::ContractAddress;
}

/// Simple contract for managing count with ownership and events.
#[starknet::contract]
pub mod Counter {
    use cairo_6::integer::{add_num, sub_num};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        count: u32,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CountIncreased: CountIncreased,
        CountDecreased: CountDecreased,
        CountReset: CountReset,
    }

    // === Individual struct for each variants
    #[derive(Drop, starknet::Event)]
    pub struct CountIncreased {
        pub amount: u32,
        pub new_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CountDecreased {
        pub amount: u32,
        pub new_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CountReset {
        pub previous_count: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[generate_trait]
    impl PrivateImpl of PrivateTrait {
        fn assert_only_owner(self: @ContractState) {
            assert(get_caller_address() == self.owner.read(), 'Caller is not owner');
        }
    }

    #[abi(embed_v0)]
    impl CounterImpl of super::ICounter<ContractState> {
        fn increase_count(ref self: ContractState, amount: u32) {
            self.assert_only_owner();
            assert(amount != 0, 'Amount cannot be 0');
            let new_count = add_num(self.count.read(), amount).expect('Amount causes overflow');
            self.count.write(new_count);
            self.emit(Event::CountIncreased(CountIncreased { amount, new_count }));
        }

        fn decrease_count(ref self: ContractState, amount: u32) {
            self.assert_only_owner();
            assert(amount != 0, 'Amount cannot be 0');
            let current_count = self.count.read();
            let new_count = sub_num(current_count, amount).expect('Amount exceeds count');
            self.count.write(new_count);
            self.emit(Event::CountDecreased(CountDecreased { amount, new_count }));
        }

        fn reset_count(ref self: ContractState) {
            self.assert_only_owner();
            let previous_count = self.count.read();
            self.count.write(0);
            self.emit(Event::CountReset(CountReset { previous_count }));
        }

        fn get_count(self: @ContractState) -> u32 {
            self.count.read()
        }

        fn get_owner(self: @ContractState) -> starknet::ContractAddress {
            self.owner.read()
        }
    }
}
