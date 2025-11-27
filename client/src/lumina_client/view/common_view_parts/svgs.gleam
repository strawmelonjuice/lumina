import lustre/attribute.{attribute, class}
import lustre/element/svg

/// Globe SVG icon used in various parts of the Lumina client.
///
/// Thank <https://www.svgrepo.com/svg/524520/earth> for this, otherwise we'd have been stuck with my older design.
pub fn globe(classes: String) {
  svg.svg(
    [
      attribute("xmlns", "http://www.w3.org/2000/svg"),
      class(classes),
      attribute("fill", "none"),
      attribute("viewBox", "0 0 24 24"),
    ],
    [
      svg.circle([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute("r", "10"),
        attribute("cy", "12"),
        attribute("cx", "12"),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M6 4.71053C6.78024 5.42105 8.38755 7.36316 8.57481 9.44737C8.74984 11.3955 10.0357 12.9786 12 13C12.7549 13.0082 13.5183 12.4629 13.5164 11.708C13.5158 11.4745 13.4773 11.2358 13.417 11.0163C13.3331 10.7108 13.3257 10.3595 13.5 10C14.1099 8.74254 15.3094 8.40477 16.2599 7.72186C16.6814 7.41898 17.0659 7.09947 17.2355 6.84211C17.7037 6.13158 18.1718 4.71053 17.9377 4",
        ),
      ]),
      svg.path([
        attribute("stroke-width", "1.5"),
        attribute("stroke", "currentColor"),
        attribute(
          "d",
          "M22 13C21.6706 13.931 21.4375 16.375 17.7182 16.4138C17.7182 16.4138 14.4246 16.4138 13.4365 18.2759C12.646 19.7655 13.1071 21.3793 13.4365 22",
        ),
      ]),
    ],
  )
}

/// Two people overlapping
/// This one is by me :) - Strawmelonjuice
pub fn follows(classes: String) {
  svg.svg(
    [
      attribute.class(classes),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      svg.circle([
        attribute.attribute("cx", "8"),
        attribute.attribute("cy", "8"),
        attribute.attribute("r", "3"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-width", "2"),
      ]),
      svg.circle([
        attribute.attribute("cx", "16"),
        attribute.attribute("cy", "8"),
        attribute.attribute("r", "3"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-width", "2"),
      ]),
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute("d", "M2 20v-1a4 4 0 0 1 4-4h4a4 4 0 0 1 4 4v1"),
      ]),
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("opacity", "0.6"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute("d", "M14 20v-1a4 4 0 0 1 4-4h0a4 4 0 0 1 4 4v1"),
      ]),
    ],
  )
}

/// Heart and star overlapping for 'mutuals'
/// Also by me :) - Strawmelonjuice
pub fn mutuals(classes: String) {
  svg.svg(
    [
      attribute.class(classes),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", "currentColor"),
      attribute.attribute("viewBox", "0 0 24 24"),
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [
      // Heart shape, offset to the left, with classic 'v' top and reduced opacity
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute(
          "d",
          "M9 19C5 15 2 12.5 2 9.5C2 7 4 5 6.5 5C8 5 9 6.5 9 6.5C9 6.5 10 5 11.5 5C14 5 16 7 16 9.5C16 12.5 13 15 9 19Z",
        ),
        attribute.attribute("opacity", "0.6"),
      ]),
      // Star shape, offset to the right and overlapping, with reduced opacity
      svg.path([
        attribute.attribute("stroke-width", "2"),
        attribute.attribute("stroke-linecap", "round"),
        attribute.attribute("stroke-linejoin", "round"),
        attribute.attribute(
          "d",
          "M15 4.5l2.09 4.24 4.68.68-3.39 3.3.8 4.63L15 15.77l-4.18 2.18.8-4.63-3.39-3.3 4.68-.68L15 4.5z",
        ),
        attribute.attribute("opacity", "0.6"),
      ]),
    ],
  )
}
