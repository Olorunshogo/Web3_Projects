use cairo_6::integer::{add_num, sub_num, multiply_num, divide_num};

#[executable]
fn main() {
    // === Addition
    let a: u32 = 20;
    let b: u32 = 7;
    match add_num(a, b) {
        Result::Ok(val) => println!("Adding {} + {} = {}.", a, b, val),
        Result::Err(err) => println!("Adding {} + {} failed: {}.", a, b, err),
    }

    // === Subtraction
    let (c, d) = (16_u32, 9_u32);
    match sub_num(c, d) {
        Result::Ok(val) => println!("Subtracting {} - {} = {}.", c, d, val),
        Result::Err(err) => println!("Subtracting {} - {} failed: {}.", c, d, err),
    }

    // Underflow case
    let (e, f) = (3_u32, 10_u32);
    match sub_num(e, f) {
        Result::Ok(val) => println!("Subtracting {} - {} = {}.", e, f, val),
        Result::Err(err) => println!("Subtracting {} - {} failed: {}.", e, f, err),
    }

    // === Multiplication
    let (g, h) = (5_u32, 6_u32);
    match multiply_num(g, h) {
        Result::Ok(val) => println!("Multiplying {} * {} = {}.", g, h, val),
        Result::Err(err) => println!("Multiplying {} * {} failed: {}.", g, h, err),
    }

    // Overflow case
    let (i, j) = (4294967295_u32, 2_u32);
    match multiply_num(i, j) {
        Result::Ok(val) => println!("Multiplying {} * {} = {}.", i, j, val),
        Result::Err(err) => println!("Multiplying {} * {} failed: {}.", i, j, err),
    }

    // === Division
    let (k, l) = (20_u32, 5_u32);
    match divide_num(k, l) {
        Result::Ok(val) => println!("{} / {} = {}", k, l, val),
        Result::Err(err) => println!("{} / {} failed: {}", k, l, err),
    }

    // By zero
    let (m, n) = (10_u32, 0_u32);
    match divide_num(m, n) {
        Result::Ok(val) => println!("Dividing {} / {} = {}.", m, n, val),
        Result::Err(err) => println!("Dividing {} / {} failed: {}.", m, n, err),
    }
}
