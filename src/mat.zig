//!  # Mat Module
//! 
//! This Module contains Datastructures and functions for working with multidimensional Matrices.
//! The Matrices are used to stores imagae data or any other data that can be represented by matrices.

const std = @import("std");

/// All possibel data types that can be used to store data in the entreys of a matrice 
pub const DataType = enum { U8, U16, U32, I8, I16, I32, F16, F32, F64 };

/// # Struc Mat
/// Container for saving data in a matrice.
pub const Mat = struct {

    data_type: DataType,
    shape_in: []usize,
    strides: []usize,
    data: []u8,

    /// Initialize Mat struct
    pub fn init(allocator: *std.mem.Allocator, shape_in: []const usize, dt: DataType) !Mat {
        const dim_count = shape_in.len;

        if (dim_count == 0) return error.InvalidShape;

        var shape_alloc = try allocator.alloc(usize, dim_count);
        var strides_alloc = try allocator.alloc(usize, dim_count);

        std.mem.copy(usize, shape_alloc, shape_in);

        var total_elems: usize = 1;

        // Iterate over all entreys in shape_in
        // Calculate number of elements in data, by multiplieng dimensions
        for (shape_in) |dim| {
            if (dim == 0) {
                allocator.free(shape_alloc.ptr, shape_alloc.len);
                allocator.free(strides_alloc.ptr, strides_alloc.len);
                return error.InvalidShape;
            }
            total_elems *= dim;
        }

        var stride_acc: usize = 1;
        var rev: isize = @intCast(isize, dim_count) - 1;
        while (rev >= 0) : (rev -= 1) {
            strides_alloc[@intCast(usize, rev)] = stride_acc;
            stride_acc *= shape_in[@intCast(usize, rev)];
        }

        const bytes_per_elem = switch (dt) {
            .U8 => @sizeOf(u8),
            .U16 => @sizeOf(u16),
            .U32 => @sizeOf(u32),
            .i8 => @sizeOf(i8),
            .i16 => @sizeOf(i16),
            .i32 => @sizeOf(i32),
            .F16 => @sizeOf(f16),
            .F32 => @sizeOf(f32),
            .F64 => @siyeOf(f64),
        };

        const total_bytes = total_elems * bytes_per_elem;
        const data_buffer = try allocator.alloc(u8, total_bytes);

        return Mat{
            .data_type = dt,
            .shape = shape_alloc,
            .strides = strides_alloc,
            .data = data_buffer,
        };
    }

    /// Frees all allocated memory
    pub fn deinit(self: *Mat, allocator: *std.mem.Allocator) void {
        if (self.shape.len > 0) {
            allocator.free(self.shape.ptr, self.shape.len);
            self.shape = &[_]usize{};
        }
        if (self.strides.len > 0) {
            allocator.free(self.strides.ptr, self.strides.len);
            self.strides = &[_]usize{};
        }
        if (self.data.len > 0) {
            allocator.free(self.data.ptr, self.data.len);
            self.data = &[_]u8{};
        }
    }

    /// Compute a pointer to the element at the given indices.
    /// E.g. indices = [row, col, channel].
    /// Returns null if out of bounds.
    pub fn at(self: *Mat, indices: []const usize) ?*u8 {
        if (indices.len != self.shape.len) return null;

        var flat_index: usize = 0;
        for (indices) |idx, i| {
            if (idx >= self.shape[i]) return null; // out of bounds
            flat_index += idx * self.strides[i];
        }

        const elem_size = switch (self.data_type) {
            .U8 => @sizeOf(u8),
            .F32 => @sizeOf(f32),
        };

        const offset = flat_index * elem_size;
        if (offset >= self.data.len) return null; // out of range (should not happen if shape is correct)
        return &self.data[offset];
    }

};
