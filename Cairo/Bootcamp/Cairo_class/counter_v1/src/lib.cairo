#[starknet::interface]
pub trait ICounter<TContractState> {
    fn increase_count(ref self: TContractState, amount: u32);
    fn get_count(self: @TContractState) -> u32;
}

#[starknet::contract]
mod Counter {
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use cairo_6::integer::add_num;
    use super::ICounter;

    #[storage]
    struct Storage {
        count: u32,
    }

    #[abi(embed_v0)]
    impl ICounterImpl of ICounter<ContractState> {
        fn increase_count(ref self: ContractState, amount: u32) {
            assert(amount != 0, 'Amount cannot be 0');
            // use add_num from the cairo_6 library to increment
            let new_count = add_num(self.count.read().try_into().unwrap(), amount.try_into().unwrap());
            self.count.write(new_count.into());
        }

        fn get_count(self: @ContractState) -> u32 {
            self.count.read()
        }
    }
}
