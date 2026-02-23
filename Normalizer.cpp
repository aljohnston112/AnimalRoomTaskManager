#include "Normalizer.h"

#include <bitset>
#include <fstream>
#include <iostream>
#include <ranges>
#include <sstream>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace Normalizer {
    enum Attribute {
        NONE,

        CRid,
        Eid,
        ELRD,

        TLid,
        RCD,

        TRid,

        //TLid RCD Rid
        RCid,
        MD,
        Tid,
        TRD,
        Mid,
        TN,
        Rid,
        TRC,
        RCS,
        RCP,
        TRV,
        MC,
        MS,
        TLA,
        TLF,
        UN,
        Uid,
        TLN,
        UGid,
        UGN,

        CD,
        ETid,
        EW,
        TA,
        CRN,
        Aid,
        QTU,
        QTmin,
        QTmax,
        RN,
        Fid,
        FN,
        FA,
        Lid,
        LC,
        LN,
        LA,
        Cid,
        AN,
        ELid,
        ELN,
        ELA,
        ETT,
        ETA,

        SIZE
    };

    const std::unordered_map<std::string, Attribute> string_to_attribute{
        {"Uid", Uid},
        {"UN", UN},
        {"UGid", UGid},
        {"UGN", UGN},
        {"TLid", TLid},
        {"TLN", TLN},
        {"TLF", TLF},
        {"TLA", TLA},
        {"Tid", Tid},
        {"TN", TN},
        {"TA", TA},
        {"QTU", QTU},
        {"QTmin", QTmin},
        {"QTmax", QTmax},
        {"Rid", Rid},
        {"RN", RN},
        {"Fid", Fid},
        {"FN", FN},
        {"FA", FA},
        {"Lid", Lid},
        {"LC", LC},
        {"LN", LN},
        {"LA", LA},
        {"TRid", TRid},
        {"TRV", TRV},
        {"TRD", TRD},
        {"TRC", TRC},
        {"Cid", Cid},
        {"CD", CD},
        {"CRid", CRid},
        {"CRN", CRN},
        {"Aid", Aid},
        {"AN", AN},
        {"ELid", ELid},
        {"ELN", ELN},
        {"ELA", ELA},
        {"ELRD", ELRD},
        {"Eid", Eid},
        {"EW", EW},
        {"ETid", ETid},
        {"ETT", ETT},
        {"ETA", ETA},
        {"RCid", RCid},
        {"RCD", RCD},
        {"RCP", RCP},
        {"RCS", RCS},
        {"Mid", Mid},
        {"MD", MD},
        {"MS", MS},
        {"MC", MC}
    };

    std::string strip(const std::string& s) {
        size_t start = 0;
        while (start < s.size() && std::isspace(s[start])) {
            ++start;
        }

        if (start == s.size()) {
            return "";
        }

        size_t end = s.size() - 1;
        while (end > start && std::isspace(s[end])) {
            --end;
        }

        return s.substr(start, end - start + 1);
    }

    std::vector<std::string> split(const std::string& s, const char delimiter) {
        std::vector<std::string> result;
        std::stringstream stringstream(s);
        std::string item;
        while (std::getline(stringstream, item, delimiter)) {
            result.push_back(strip(item));
        }
        return result;
    }

    void print_functional_dependencies(
        const std::unordered_map<
            uint64_t,
            uint64_t
        >& functional_dependencies
    ) {
        for (const auto& [
                 determinants,
                 determined
             ] : functional_dependencies
        ) {
            std::cout << "{ ";
            for (size_t i = 0; i < SIZE; ++i) {
                if ((determinants & (1ULL << i)) > 0) {
                    for (const auto& [
                             name,
                             attribute
                         ] : string_to_attribute
                    ) {
                        if (static_cast<size_t>(attribute) == i) {
                            std::cout << name << " ";
                            break;
                        }
                    }
                }
            }
            std::cout << "} -> { ";
            for (size_t i = 0; i < SIZE; ++i) {
                if ((determined & (1ULL << i)) > 0) {
                    for (const auto& [
                             name,
                             attribute
                         ] : string_to_attribute
                    ) {
                        if (static_cast<size_t>(attribute) == i) {
                            std::cout << name << " ";
                            break;
                        }
                    }
                }
            }
            std::cout << "}\n";
        }
    }

    bool load_functional_dependencies(
        const std::string& filename,
        std::unordered_map<
            uint64_t,
            uint64_t
        >& functional_dependencies
    ) {
        std::ifstream input_file_stream(filename, std::ios::in);
        if (!input_file_stream.is_open()) {
            std::cout << "Failed to open " << filename << "\n";
            return true;
        }

        functional_dependencies = {};
        uint64_t determinants{};
        for (std::string line; std::getline(input_file_stream, line);) {
            if (line.find("(") == std::string::npos && line.size() > 0) {
                if (line.find("\t") == std::string::npos) {
                    if (line.find(",") == std::string::npos) {
                        determinants |=
                            1ULL << static_cast<std::size_t>(
                                string_to_attribute.at(line)
                            );
                    } else {
                        for (const auto attribute_strings = split(
                                 line,
                                 ','
                             );
                             const auto& attribute : attribute_strings
                        ) {
                            determinants |=
                                1ULL << static_cast<std::size_t>(
                                    string_to_attribute.at(attribute)
                                );
                        }
                    }
                } else {
                    uint64_t determined{};
                    for (const auto attribute_strings = split(
                             line,
                             ','
                         );
                         const auto& attribute : attribute_strings
                    ) {
                        determined |=
                            1ULL << static_cast<std::size_t>(
                                string_to_attribute.at(attribute)
                            );
                    }
            if (functional_dependencies.contains(determinants)) {
                functional_dependencies[determinants] |= determined;
            } else {
                functional_dependencies[determinants] = determined;
            }
                    determinants = 0;
                }
            }
        }
        return false;
    }

    void get_closure_of_determinants(
        const std::unordered_map<uint64_t, uint64_t>& functional_dependencies,
        uint64_t& determinants
    ) {
        bool changed;
        do {
            changed = false;
            for (const auto [
                     determinant,
                     determined
                 ] : functional_dependencies
            ) {
                if ((determinant & determinants) == determinant) {
                    if ((determined & determinants) != determined) {
                        changed = true;
                        determinants |= determined;
                    }
                }
            }
        } while (changed);
    }

    void calculate_closure(
        const std::unordered_map<uint64_t, uint64_t>& functional_dependencies,
        std::unordered_map<uint64_t, uint64_t>& closure
    ) {
        for (const uint64_t determinant :
             functional_dependencies | std::views::keys
        ) {
            uint64_t determined_closure = determinant;
            get_closure_of_determinants(
                functional_dependencies,
                determined_closure
            );
            if (closure.contains(determinant)) {
                closure[determinant] |= determined_closure;
            } else {
                closure[determinant] = determined_closure;
            }
        }
    }

    constexpr uint64_t mandatory_attributes = 0b111;
    constexpr uint64_t non_mandatory_bit_shift =
        std::bit_width(mandatory_attributes);
    constexpr uint64_t first_non_mandatory_bit =
        1 << non_mandatory_bit_shift;
    constexpr uint64_t number_of_non_mandatory_bits =
        static_cast<uint64_t>(SIZE) - 1 - non_mandatory_bit_shift;

    struct ArrayHash {
        std::size_t operator()(
            const std::array<bool, number_of_non_mandatory_bits>& array
        ) const noexcept {
            std::size_t seed = 0;
            for (int i = 0; i < array.size(); i++) {
                if (array[i]) {
                    seed |= (1ULL << i);
                }
            }
            return seed;
        }
    };

    void find_candidate_keys(
        const std::unordered_map<uint64_t, uint64_t>& functional_dependencies,
        std::unordered_set<uint64_t>& candidate_keys
    ) {
        uint64_t all_keys = 0;
        for (uint64_t attribute_index = 0;
             attribute_index < static_cast<uint64_t>(SIZE);
             attribute_index++
        ) {
            all_keys |= (1ULL << attribute_index);
        }

        uint64_t closure = mandatory_attributes;
        get_closure_of_determinants(
            functional_dependencies,
            closure
        );
        if (closure == all_keys) {
            candidate_keys.emplace(mandatory_attributes);
        }

        for (uint64_t number_of_non_mandatory_attributes = 1;
             number_of_non_mandatory_attributes < number_of_non_mandatory_bits;
             number_of_non_mandatory_attributes++
        ) {
            std::array<bool, number_of_non_mandatory_bits> permutation{};
            for (uint64_t i = 0; i < number_of_non_mandatory_attributes; i++) {
                permutation[permutation.size() - i - 1] = true;
            }
            do {
                uint64_t current_key = mandatory_attributes;
                for (uint64_t j = 0; j < permutation.size(); j++) {
                    current_key |=
                    (static_cast<uint64_t>(permutation[j]) <<
                        non_mandatory_bit_shift) << j;
                }
                bool found = false;
                for (const auto key : candidate_keys) {
                    if ((current_key & key) == key) {
                        found = true;
                        break;
                    }
                }
                if (found) {
                    continue;
                }

                uint64_t c = current_key;
                get_closure_of_determinants(
                    functional_dependencies,
                    c
                );
                if (c == all_keys) {
                    candidate_keys.emplace(current_key);
                }
            } while (std::next_permutation(
                    permutation.begin(),
                    permutation.end())
            );
        }
    }

    void print_candidate_keys(
        const std::unordered_set<uint64_t>& candidate_keys
    ) {
        std::cout << "{ \n";
        for (const auto attribute : candidate_keys) {
            std::cout << "    { ";
            for (size_t i = 0; i < SIZE; ++i) {
                if ((attribute & (1ULL << i)) > 0) {
                    for (const auto& [
                             name,
                             attribute
                         ] : string_to_attribute
                    ) {
                        if (static_cast<size_t>(attribute) == i) {
                            std::cout << name << ", ";
                            break;
                        }
                    }
                }
            }
            std::cout << "\n}\n";
        }
        std::cout << "}";
    }

    void print_3NF(const std::string& filename) {
        std::unordered_map<
            uint64_t,
            uint64_t
        > functional_dependencies{};
        if (load_functional_dependencies(
                filename,
                functional_dependencies
            )
        ) {
            return;
        }


        print_functional_dependencies(functional_dependencies);
        std::cout << std::endl;
        std::unordered_map<
            uint64_t,
            uint64_t
        > closure{};
        calculate_closure(functional_dependencies, closure);
        print_functional_dependencies(closure);
        std::cout << std::endl;

        // Was used to determine candidate keys by hand
        // uint64_t c = 0b1111111;
        // get_closure_of_determinants(
        //     functional_dependencies,
        //     c
        // );
        // std::cout << "    { ";
        // int size = 0;
        // for (size_t i = 0; i < SIZE; ++i) {
        //     if ((c & (1ULL << i)) > 0) {
        //         for (const auto& [
        //                  name,
        //                  attribute
        //              ] : string_to_attribute
        //         ) {
        //             if (static_cast<size_t>(attribute) == i) {
        //                 std::cout << name << " ";
        //                 size++;
        //                 break;
        //             }
        //         }
        //     }
        // }
        // std::cout << "}" << size << "\n";
        std::unordered_set<uint64_t> candidate_keys{};
        find_candidate_keys(closure, candidate_keys);
        print_candidate_keys(candidate_keys);
    }
}
