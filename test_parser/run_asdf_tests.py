import run_tests
import os.path

if __name__ == '__main__':

    restrict_to_path = None
    """
    if len(sys.argv) == 2:
        restrict_to_path = os.path.join(BASE_DIR, sys.argv[1])
        if not os.path.exists(restrict_to_path):
            print("-- file does not exist:", restrict_to_path)
            sys.exit(-1)
    """
    #restrict_to_program = ["Python 2.7.10", "Python 3.5.2"]

    asdf_config = "Mir Ion Parser";

    run_tests.programs[ion_config] = {
       "url":"https://github.com/libmir/ion",
       "commands":[os.path.join(run_tests.PARSERS_DIR, "../../test_json-ion")]
   }

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('restrict_to_path', nargs='?', type=str, default=None)

    args = parser.parse_args()
    run_tests.run_tests(args.restrict_to_path, [ion_config])

    run_tests.generate_report(os.path.join(run_tests.BASE_DIR, "results/parsing.html"), keep_only_first_result_in_set = False)
    run_tests.generate_report(os.path.join(run_tests.BASE_DIR, "results/parsing_pruned.html"), keep_only_first_result_in_set = True)
