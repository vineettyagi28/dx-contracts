pragma solidity ^0.4.19;

import "../Oracle/DSValue.sol";

contract Medianizer is DSValue {
    mapping (bytes12 => address) public values;
    mapping (address => bytes12) public indexes;
    bytes12 public next = 0x1;

    uint96 public min = 0x1;

    function set(address wat) auth {
        bytes12 nextId = bytes12(uint96(next) + 1);
        assert(nextId != 0x0);
        set(next, wat);
        next = nextId;
    }

    function set(bytes12 pos, address wat) note auth {
        if (pos == 0x0) throw;

        if (wat != 0 && indexes[wat] != 0) throw;

        indexes[values[pos]] = 0; // Making sure to remove a possible existing address in that position

        if (wat != 0) {
            indexes[wat] = pos;
        }

        values[pos] = wat;
    }

    function setMin(uint96 min_) note auth {
        if (min_ == 0x0) throw;
        min = min_;
    }

    function setNext(bytes12 next_) note auth {
        if (next_ == 0x0) throw;
        next = next_;
    }

    function unset(bytes12 pos) {
        set(pos, 0);
    }

    function unset(address wat) {
        set(indexes[wat], 0);
    }

    function poke() {
        poke(0);
    }

    function poke(bytes32) note {
        (val, has) = compute();
    }

    function compute() constant returns (bytes32, bool) {
        bytes32[] memory wuts = new bytes32[](uint96(next) - 1);
        uint96 ctr = 0;
        for (uint96 i = 1; i < uint96(next); i++) {
            if (values[bytes12(i)] != 0) {
                var (wut, wuz) = DSValue(values[bytes12(i)]).peek();
                if (wuz) {
                    if (ctr == 0 || wut >= wuts[ctr - 1]) {
                        wuts[ctr] = wut;
                    } else {
                        uint96 j = 0;
                        while (wut >= wuts[j]) {
                            j++;
                        }
                        for (uint96 k = ctr; k > j; k--) {
                            wuts[k] = wuts[k - 1];
                        }
                        wuts[j] = wut;
                    }
                    ctr++;
                }
            }
        }

        if (ctr < min) return (val, false);

        bytes32 value;
        if (ctr % 2 == 0) {
            uint128 val1 = uint128(wuts[(ctr / 2) - 1]);
            uint128 val2 = uint128(wuts[ctr / 2]);
            value = bytes32(wdiv(hadd(val1, val2), 2 ether));
        } else {
            value = wuts[(ctr - 1) / 2];
        }

        return (value, true);
    }
}
