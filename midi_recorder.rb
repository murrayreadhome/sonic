# midi_recorder - records midi notes, then prints what was played
# Start the script, play your midi device, then 5 beats after
# you finish the note sequence will be printed as a list.
# Each list item is [note, velocity, start time, duration].

use_debug false
current_down = []
last_up = []
sequence = []
kbd = "/midi*/note_on"
resolution = 0.125
b = 0
last_event_time = 0
seq_start = -1

define :note_start do |note, amp|
  t = b - seq_start
  note_record = [note, amp, t]
  current_down += [note_record]
end

define :note_end do |note|
  t = b - seq_start
  ended = []
  current_down.each do |down|
    if down[0].equal?(note)
      ended += [down]
    end
  end
  ended.each do |up|
    info = up + [t-up[2]]
    last_up += [info]
  end
  current_down = current_down - ended
end

define :show_played do
  if !last_up.empty? and last_event_time+resolution < b
    sequence += last_up
    last_up = []
  end
  if !sequence.empty? and last_event_time+5 < b
    sequence.sort! { |a,b| a[2] <=> b[2] }
    print sequence
    sequence = []
    seq_start = -1
  end
end

live_loop :recorder do
  use_real_time
  note, amp = sync kbd
  last_event_time = b
  if seq_start==-1
    seq_start = b
  end
  if amp==0
    note_end(note)
  else
    note_start(note, amp)
  end
  
  play note, amp: amp/127.0
end

live_loop :metronome do
  use_real_time
  if factor?(b,1)
    sample :perc_snap, amp: 0.4
  end
  sleep resolution
  b = b + resolution
  show_played
end
