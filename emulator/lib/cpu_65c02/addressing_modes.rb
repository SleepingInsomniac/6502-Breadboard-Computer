class CPU65c02
  ADDRESSING_MODES = {
    'a'      => 'Absolute',
    '(a,x)'  => 'Absolute Indexed Indirect',
    'a,x'    => 'Absolute Indexed with X',
    'a,y'    => 'Absolute Indexed with Y',
    '(a)'    => 'Absolute Indirect',
    'A'      => 'Accumulator',
    '#'      => 'Immediate',
    'i'      => 'Implied',
    'r'      => 'Program Counter Relative',
    's'      => 'Stack',
    'zp'     => 'Zero Page',
    '(zp,x)' => 'Zero Page Indexed Indirect',
    'zp,x'   => 'Zero Page Indexed with X',
    'zp,y'   => 'Zero Page Indexed with Y',
    '(zp)'   => 'Zero Page Indirect',
    '(zp),y' => 'Zero Page Indirect Indexed with Y',
  }
end
