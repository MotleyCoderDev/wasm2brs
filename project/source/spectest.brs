' Copyright 2020, Trevor Sundberg. See LICENSE.md
Function spectest_print()
End Function

Function spectest_print_i32(p1 as Integer)
    Print p1
End Function

Function spectest_print_i32_f32(p1 as Integer, p2 as Float)
    Print p1 p2
End Function

Function spectest_print_f32(p1 as Float)
    Print p1
End Function

Function spectest_print_f64(p1 as Double)
    Print p1
End Function

Function spectest_print_f64_f64(p1 as Double, p2 as Double)
    Print p1 p2
End Function

Function InitSpectest()
    m.spectest_table = []
    m.spectest_global_i32 = 666%
    m.spectest_global_f32 = 0!
    m.spectest_global_f64 = 0#
    m.spectest_memory = CreateObject("roByteArray")
    m.spectest_memoryMax = 2
    MemoryGrow(m.spectest_memory, m.spectest_memoryMax, 1)
    I32Store(m.spectest_memory, 10, 16)
End Function
