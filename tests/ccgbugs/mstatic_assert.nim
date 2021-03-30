{.emit:"""
NIM_STATIC_ASSERT(sizeof(bool) == 1, "");
#warning "foo2"
NIM_STATIC_ASSERT(sizeof(bool) == 2, "");
#warning "foo3"
""".}
