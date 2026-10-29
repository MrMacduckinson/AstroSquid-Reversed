import unittest
from compare_world_return import canonical


class ListMappingTest(unittest.TestCase):
    rows = ['R\t0\tgameover-tail\t1\t0\t2\told\t0',
            'R\t0\tgameover-tail\t2\t1\t3\tui\t0',
            'R\t0\tgameover-tail\t3\t2\t0\tnew\t1',
            'E\t0\tgameover-tail\t8\t3\t0\t0\t0\tentity']

    def test_splice_and_identity(self):
        self.assertEqual(canonical(self.rows, {'2'}), [
            'R\tT\tgameover-tail\t1\t0\t2\told\t0',
            'R\tT\tgameover-tail\t2\t1\t0\tnew\t1',
            'E\tT\tgameover-tail\t8\t2\t0\t0\t0\tentity'])

    def test_reject_broken_backlink(self):
        broken = self.rows.copy()
        broken[2] = broken[2].replace('\t3\t2\t0\t', '\t3\t0\t0\t')
        with self.assertRaises(AssertionError):
            canonical(broken, {'2'})


if __name__ == '__main__':
    unittest.main()
