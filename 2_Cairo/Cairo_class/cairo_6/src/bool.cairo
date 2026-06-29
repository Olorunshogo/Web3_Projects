#[executable]
fn main() {
    let result: bool = is_adult(20);
    println!("Is the person an adult? {}", result);

    let is_even_result: bool = is_even(0);
    println!("Is the number even? {}", is_even_result);
}

// function to check if a person is an adult
fn is_adult(x: u8) -> bool {
    if x >= 18 {
        return true;
    } else {
        return false;
    }
}

// function to check if a number is even
fn is_even(x: u8) -> bool {
    if x % 2 == 0 {
        return true;
    } else {
        return false;
    }
}
