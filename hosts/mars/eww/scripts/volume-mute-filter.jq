.[]
| { id: .id }
  * ( .info.params.Props
      | map(
          select(
            (.volume != null) and
            (.mute != null)
          )
          | { volume: .volume
            , mute: .mute
            }
        )
      | flatten[]
    )
