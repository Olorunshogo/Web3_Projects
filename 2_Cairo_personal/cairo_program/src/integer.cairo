// === Arithmetic Functions
pub fn add_num(x: u32, y: u32) -> Result<u32, felt252> {
    let result: u256 = x.into() + y.into();
    result.try_into().ok_or('Addition overflow')
}

pub fn sub_num(x: u32, y: u32) -> Result<u32, felt252> {
    if x < y {
        Result::Err('Subtraction underflow')
    } else {
        Result::Ok(x - y)
    }
}

pub fn multiply_num(x: u32, y: u32) -> Result<u32, felt252> {
    let result: u256 = x.into() * y.into();
    result.try_into().ok_or('Multiplication overflow')
}

pub fn divide_num(x: u32, y: u32) -> Result<u32, felt252> {
    if y == 0 {
        Result::Err('Division by zero')
    } else {
        Result::Ok(x / y)
    }
}

// === Tests
#[cfg(test)]
mod tests {
    use super::{add_num, sub_num, multiply_num, divide_num};

    #[test]
    fn test_add_num() {
        assert!(add_num(20, 7) == Result::Ok(27), "add failed");
    }

    #[test]
    fn test_sub_num_ok() {
        assert!(sub_num(16, 9) == Result::Ok(7), "sub failed");
    }

    #[test]
    fn test_sub_num_underflow() {
        assert!(sub_num(3, 10) == Result::Err('Subtraction underflow'), "underflow check failed");
    }

    #[test]
    fn test_multiply_num() {
        assert!(multiply_num(5, 6) == Result::Ok(30), "multiply failed");
    }

    #[test]
    fn test_divide_num_ok() {
        assert!(divide_num(20, 5) == Result::Ok(4), "divide failed");
    }

    #[test]
    fn test_divide_by_zero() {
        assert!(divide_num(10, 0) == Result::Err('Division by zero'), "div zero check failed");
    }
}
