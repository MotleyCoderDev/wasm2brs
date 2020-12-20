use std::io::{self, BufRead};

fn main() {
    loop {
        println!("Write something and we'll echo it back:");
        let stdin = io::stdin();
        let line = stdin.lock()
            .lines()
            .next()
            .expect("There was no next line")
            .expect("The line could not be read");
            println!("You wrote: {}", line);
    }
}
