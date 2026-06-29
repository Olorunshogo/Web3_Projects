// === Arithmetic Functions

pub fn add_num(x: u8, y: u8) -> u8 {
    x + y
}

pub fn sub_num(x: u8, y: u8) -> u8 {
    assert!(!(y > x), "Subtraction should not be negative");
    x - y
}

pub fn sub_number(x: u32, y: u32) -> Result<u32, felt252> {
    if x < y {
        Result::Err('Negative result')
    } else {
        Result::Ok(x - y)
    }
}

pub fn multiply_num(x: u8, y: u8) -> u8 {
    x * y
}

pub fn divide_num(x: u8, y: u8) -> u8 {
    assert!(y != 0, "Division by zero is not allowed");
    x / y
}
