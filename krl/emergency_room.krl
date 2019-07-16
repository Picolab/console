ruleset emergency_room {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares __testing, children
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "children", "args": [ "id" ] }
      ] , "events":
      [ { "domain": "er", "type": "rogue_pico" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    rogue_name = "rogue_loss"
    children = function(id){
      wrangler:children(id)
    }
  }
  rule check_for_channel {
    select when er rogue_pico
      where wrangler:children().length() == 1
    if wrangler:channel(rogue_name).isnull() then
      wrangler:createChannel(ent:picoId,rogue_name,"er")
  }
  rule delete_rogue_pico {
    select when er rogue_pico
      where wrangler:children().length() == 1
    pre {
      child = children(rogue_name).head()
    }
    if child && child{"id"} then noop()
    fired {
      raise wrangler event "delete_child" attributes {
        "id": child{"id"},
        "target": true,
        "updated_children": {},
        "child_name": rogue_name,
      }
    }
  }
}
