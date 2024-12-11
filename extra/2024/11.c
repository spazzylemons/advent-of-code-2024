#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <inttypes.h>

struct entry {
    uint64_t stone;
    uint64_t count;
};

struct map {
    size_t size;
    size_t capacity;
    struct entry *entries;
};

static struct entry *find(const struct map *map, uint64_t stone) {
    size_t mask = map->capacity - 1;
    size_t index = stone & mask;
    for (;;) {
        struct entry *entry = &map->entries[index];
        if (!entry->count || entry->stone == stone)
            return entry;
        index = (index + 1) & mask;
    }
}

static void insert_no_grow(struct map *map, uint64_t stone, uint64_t count) {
    struct entry *entry = find(map, stone);
    entry->stone = stone;
    entry->count += count;
    ++map->size;
}

static void insert(struct map *map, uint64_t stone, uint64_t count) {
    if (map->size * 4 >= map->capacity * 3) {
        struct entry *old = map->entries;
        size_t old_size = map->capacity;
        map->size = 0;
        map->capacity *= 2;
        map->entries = calloc(map->capacity, sizeof(struct entry));
        for (size_t i = 0; i < old_size; i++) {
            const struct entry *entry = &old[i];
            if (entry->count) insert_no_grow(map, entry->stone, entry->count);
        }
        free(old);
    }
    insert_no_grow(map, stone, count);
}

static void parse(FILE *file, struct map *map) {
    uint64_t value;
    while (fscanf(file, "%" PRIu64, &value) == 1) {
        insert(map, value, 1);
    }
}

static void new_map(struct map *map, size_t capacity) {
    map->size = 0;
    map->capacity = capacity;
    map->entries = calloc(capacity, sizeof(struct entry));
}

static int count_digits(uint64_t stone) {
    int result = 1;
    while (stone >= 10) {
        ++result;
        stone /= 10;
    }
    return result;
}

static uint64_t digit_multiply(int i) {
    uint64_t result = 1;
    for (int j = 0; j < i; j++)
        result *= 10;
    return result;
}

static void blink(struct map *map) {
    struct map next;
    new_map(&next, map->capacity);

    for (size_t i = 0; i < map->capacity; i++) {
        const struct entry *entry = &map->entries[i];
        uint64_t count = entry->count;
        if (!count) continue;

        uint64_t stone = entry->stone;
        if (stone == 0) {
            insert(&next, 1, count);
        } else {
            int digit_count = count_digits(stone);
            if (digit_count & 1) {
                insert(&next, 2024 * stone, count);
            } else {
                uint64_t m = digit_multiply(digit_count >> 1);
                insert(&next, stone / m, count);
                insert(&next, stone % m, count);
            }
        }
    }

    free(map->entries);
    *map = next;
}

static uint64_t get_result(const struct map *map) {
    uint64_t result = 0;

    for (size_t i = 0; i < map->capacity; i++) {
        const struct entry *entry = &map->entries[i];
        result += entry->count;
    }

    return result;
}

static void run_blinks(struct map *map, int count) {
    for (int i = 0; i < count; i++) blink(map);
}

int main(void) {
    struct map map;
    new_map(&map, 8);

    FILE *f = fopen("input/2024/11.txt", "r");
    if (f == NULL) return EXIT_FAILURE;
    parse(f, &map);
    fclose(f);

    run_blinks(&map, 25);
    printf("Part 1: %" PRIu64 "\n", get_result(&map));
    run_blinks(&map, 50);
    printf("Part 2: %" PRIu64 "\n", get_result(&map));

    free(map.entries);
    return EXIT_SUCCESS;
}
