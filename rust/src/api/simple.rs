#[flutter_rust_bridge::frb(sync)] // Synchronous mode for simplicity of the demo
pub fn greet(name: String) -> String {
    println!("hello world");
    tracing::info!("from rust: info! ");
    tracing::debug!("from rust: debug! ");
    tracing::trace!("from rust: trace! ");
    tracing::error!("from rust: error! ");
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Default utilities - feel free to customize
    flutter_rust_bridge::setup_default_user_utils();
}
