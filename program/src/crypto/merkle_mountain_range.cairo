from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.memset import memset

const MMR_ROOTS_LEN = 27;  // ~ log2( 100,000,000 headers )

// Append a leaf to the Merkle mountain range
//
func mmr_append{hash_ptr: HashBuiltin*, mmr_roots: felt*}(leaf) {
    alloc_locals;
    let roots_out:felt* = alloc();
    _mmr_append_loop(mmr_roots, roots_out, leaf, 0);
    let mmr_roots = roots_out;
    return ();
}

func _mmr_append_loop{hash_ptr: HashBuiltin*}(roots_in: felt*, roots_out: felt*, node, height) {
    let root = roots_in[height];

    if (root == 0) {
        assert roots_out[height] = node;
        let height = height + 1;
        memcpy(roots_out + height, roots_in + height, MMR_ROOTS_LEN - height);
        return ();
    }

    let (node) = hash2(root, node);

    assert roots_out[height] = 0;

    return _mmr_append_loop(roots_in, roots_out, node, height + 1);
}

// Append an array of leaves to the Merkle mountain range
//
func mmr_append_leaves{hash_ptr: HashBuiltin*, mmr_roots: felt*}(leaves: felt*, n_leaves) {
    if (n_leaves == 0) {
        return ();
    }
    mmr_append([leaves]);
    return mmr_append_leaves(leaves + 1, n_leaves-1);
}
