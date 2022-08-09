foreach (inputs, null) as $entry
  ( null
  ; if $entry then .nodes =
      if . != null
      then .nodes | map(select(.id != $entry[].id)) | unique_by(.id)
      else .nodes end

      + [ $entry[]
          | select(
              (.type == "PipeWire:Interface:Node") and
              (.info.state != "suspended") and
              (.info.params.Props != null)
            )
          | { id: .info.props."object.id"
            , name: 
                ( if .info.props."media.name" != null
                  then .info.props."media.name"
                  else .info.props."node.description" end
                )
            , state: .info.state
            , node_name: .info.props."node.name"
            , class: .info.props."media.class"
            }
            * ( .info.params.Props
                | map(
                    select(.volume != null)
                    | { volume: .volume
                      , mute: .mute
                      }
                  )
                | .[]
              )
        ]
    else . end
  )
  | .nodes | sort_by(.name)
