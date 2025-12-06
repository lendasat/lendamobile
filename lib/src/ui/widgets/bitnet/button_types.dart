/// Button state enum for button loading/disabled states
enum ButtonState {
  /// Normal idle state
  idle,

  /// Loading state with spinner
  loading,

  /// Disabled state
  disabled,
}

/// Button type enum for styling buttons
enum ButtonType {
  /// Solid background button
  solid,

  /// Transparent button with minimal styling
  transparent,

  /// Outlined button with border
  outlined,

  /// Primary action button
  primary,

  /// Secondary action button
  secondary,

  /// Disabled button
  disabled,
}
