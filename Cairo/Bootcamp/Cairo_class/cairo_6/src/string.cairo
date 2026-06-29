#[executable]
fn main() {
    // Short string
    let bootcamp_name: felt252 = 'Cohort 8';
    println!("The name of our bootcamp is: {}", bootcamp_name);

    // Long String
    let long_string: ByteArray = "We are writing Cairo in this session and it's going to be fun";
    println!("The long string is: {}", long_string);
}
