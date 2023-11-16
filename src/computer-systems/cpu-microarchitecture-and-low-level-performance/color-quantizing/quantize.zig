const std = @import("std");

const RED0: c_char = 0x00;
const RED1: c_char = 0x20;
const RED2: c_char = 0x40;
const RED3: c_char = 0x60;
const RED4: c_char = 0x80;
const RED5: c_char = 0xa0;
const RED6: c_char = 0xc0;
const RED7: c_char = 0xe0;
const GREEN0: c_char = 0x00;
const GREEN1: c_char = 0x04;
const GREEN2: c_char = 0x08;
const GREEN3: c_char = 0x0c;
const GREEN4: c_char = 0x10;
const GREEN5: c_char = 0x14;
const GREEN6: c_char = 0x18;
const GREEN7: c_char = 0x1c;
const BLUE0: c_char = 0x00;
const BLUE1: c_char = 0x01;
const BLUE2: c_char = 0x02;
const BLUE3: c_char = 0x03;

export fn quantize(red: c_char, green: c_char, blue: c_char) callconv(.C) c_char {
    var out: c_char = 0;
    if (red < 0x20) {
        out += RED0;
    } else if (red < 0x40) {
        out += RED1;
    } else if (red < 0x60) {
        out += RED2;
    } else if (red < 0x80) {
        out += RED3;
    } else if (red < 0xa0) {
        out += RED4;
    } else if (red < 0xc0) {
        out += RED5;
    } else if (red < 0xe0) {
        out += RED6;
    } else {
        out += RED7;
    }

    if (green < 0x20) {
        out += GREEN0;
    } else if (green < 0x40) {
        out += GREEN1;
    } else if (green < 0x60) {
        out += GREEN2;
    } else if (green < 0x80) {
        out += GREEN3;
    } else if (green < 0xa0) {
        out += GREEN4;
    } else if (green < 0xc0) {
        out += GREEN5;
    } else if (green < 0xe0) {
        out += GREEN6;
    } else {
        out += GREEN7;
    }

    if (blue < 0x40) {
        out += BLUE0;
    } else if (blue < 0x80) {
        out += BLUE1;
    } else if (blue < 0xc0) {
        out += BLUE2;
    } else {
        out += BLUE3;
    }

    return out;
}
